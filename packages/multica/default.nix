# Our multica wiring: the multica-nix flake input provides the NixOS module;
# services.multica config and the secrets service live here. Skill bodies live in
# ./skills/*.md; agent instructions in ./agents/*.md.
{ multica-nix, ... }:

{
  imports = [
    multica-nix.nixosModules.multica
  ];

  # Hardcode multica secrets directly (not exposed outside VM, and multica by design is not secure)
  environment.etc."multica/multica.env" = {
    text = ''
      JWT_SECRET=5e725324fcefb921e151465397495bf8276e18a78630bc39b2b25bc6b56b94f8
    '';
    mode = "0600";
  };

  # Multica self-hosted server (github.com/multica-ai/multica), run declaratively via
  # the ../../multica-nix module: native Postgres 17 + pgvector, docker backend (:8080) and
  # web (:3000) containers on host networking, all bound to loopback.
  services.multica = {
    enable = true;
    installDesktop = true;
    environmentFile = "/etc/multica/multica.env";
    # Log in as the account that owns the "test" workspace so declared skills
    # land where they are visible in the app.
    devLoginEmail = "james@james.com";
    # Default skill + agent set, genericised from a working workspace export.
    # Skill bodies live in ./skills/*.md; agent instructions in
    # ./agents/*.md. The 8 integration skills carry <PLACEHOLDER> tokens
    # (see each skill's "Configure for your workspace" section) — fill them in per
    # customer. The source agents each carried 11 secret integration env vars; those
    # are NOT reproduced here (recreate per agent via `customEnvFile` when needed).
    # Models: the source used claude-opus-5 / -sonnet-5 / -haiku; mapped to this
    # runtime's current IDs below — bump if your runtime exposes the -5 line.
    skills.agent-browser = {
      description = "Drive a headless Chromium from the CLI for UI evidence — rendered pages, screenshots, authenticated flows.";
      source = ./skills/agent-browser.md;
    };
    skills.aws = {
      description = "Run AWS CLI commands against your account (ECS, RDS, CloudFront, Lambda, S3, Logs, SSM, Cost Explorer). Env-var auth.";
      source = ./skills/aws.md;
    };
    skills.gitlab = {
      description = "Work with GitLab repos via glab — browse/search, read files, list/create MRs, inline review comments, push branches.";
      source = ./skills/gitlab.md;
    };
    skills.jira = {
      description = "Query, create and update Jira issues via acli — JQL search, transitions, comments, ADF descriptions. Confirmation required before creating.";
      source = ./skills/jira.md;
    };
    skills.newrelic = {
      description = "Query New Relic APM for your platform — service health, throughput, errors, traces, deploy markers (NerdGraph/NRQL).";
      source = ./skills/newrelic.md;
    };
    skills.obsidian = {
      description = "Search and read an Obsidian knowledge vault from the CLI with ripgrep/fd — notes, tags, backlinks.";
      source = ./skills/obsidian.md;
    };
    skills.open-pr = {
      description = "Automate the first half of the GitLab MR lifecycle — validate, push, open a draft MR, poll CI, address review. Never merges or undrafts.";
      source = ./skills/open-pr.md;
    };
    skills.sentry = {
      description = "Debug Sentry issues for your platform from the CLI — list/inspect issues, events, releases.";
      source = ./skills/sentry.md;
    };
    skills.signoz = {
      description = "Query your self-hosted SigNoz instance for distributed traces, logs and service health.";
      source = ./skills/signoz.md;
    };

    agents.adversarial-reviewer = {
      description = "Independent skeptic — tries to refute findings and surface how a change could go wrong before it ships.";
      runtime = "Claude (carverlinux)";
      model = "claude-opus-4-8";
      thinkingLevel = "high";
      visibility = "private";
      maxConcurrentTasks = 1;
      instructions = builtins.readFile ./agents/adversarial-reviewer.md;
      skills = [ "agent-browser" "obsidian" ];
    };
    agents.architect = {
      description = "Designs implementation approaches and weighs architectural trade-offs.";
      runtime = "Claude (carverlinux)";
      model = "claude-opus-4-8";
      thinkingLevel = "high";
      visibility = "private";
      maxConcurrentTasks = 1;
      instructions = builtins.readFile ./agents/architect.md;
      skills = [ "agent-browser" "aws" "gitlab" "jira" "newrelic" "obsidian" "open-pr" "sentry" "signoz" ];
    };
    agents.backend-dev = {
      description = "Implements backend features and fixes.";
      runtime = "Claude (carverlinux)";
      model = "claude-sonnet-4-6";
      thinkingLevel = "medium";
      visibility = "private";
      maxConcurrentTasks = 3;
      instructions = builtins.readFile ./agents/backend-dev.md;
      skills = [ "agent-browser" "aws" "gitlab" "jira" "newrelic" "obsidian" "open-pr" "sentry" "signoz" ];
    };
    agents.code-reviewer = {
      description = "Reviews changes for correctness and quality.";
      runtime = "Claude (carverlinux)";
      model = "claude-opus-4-8";
      thinkingLevel = "high";
      visibility = "private";
      maxConcurrentTasks = 1;
      instructions = builtins.readFile ./agents/code-reviewer.md;
      skills = [ "agent-browser" "obsidian" "open-pr" ];
    };
    agents.code-simplifier = {
      description = "Reviews changed code for reuse, simplification and efficiency, then applies fixes.";
      runtime = "Claude (carverlinux)";
      model = "claude-sonnet-4-6";
      thinkingLevel = "high";
      visibility = "private";
      maxConcurrentTasks = 1;
      # Source carried a personal --settings path in customArgs; dropped.
      instructions = builtins.readFile ./agents/code-simplifier.md;
      skills = [ "agent-browser" ];
    };
    agents.dev-experience-reviewer = {
      description = "Reviews developer-experience and tooling changes.";
      runtime = "Claude (carverlinux)";
      model = "claude-opus-4-8";
      thinkingLevel = "high";
      visibility = "private";
      maxConcurrentTasks = 6;
      instructions = builtins.readFile ./agents/dev-experience-reviewer.md;
      skills = [ "agent-browser" "gitlab" "jira" "newrelic" "obsidian" "open-pr" "sentry" "signoz" ];
    };
    agents.frontend-dev = {
      description = "Implements frontend features and fixes.";
      runtime = "Claude (carverlinux)";
      model = "claude-sonnet-4-6";
      thinkingLevel = "medium";
      visibility = "private";
      maxConcurrentTasks = 1;
      instructions = builtins.readFile ./agents/frontend-dev.md;
      skills = [ "agent-browser" "aws" "gitlab" "jira" "newrelic" "obsidian" "open-pr" "sentry" "signoz" ];
    };
    agents.ops-engineer = {
      description = "Handles infrastructure and operational tasks.";
      runtime = "Claude (carverlinux)";
      model = "claude-sonnet-4-6";
      thinkingLevel = "high";
      visibility = "private";
      maxConcurrentTasks = 4;
      instructions = builtins.readFile ./agents/ops-engineer.md;
      skills = [ "agent-browser" "aws" "gitlab" "jira" "newrelic" "obsidian" "open-pr" "sentry" "signoz" ];
    };
    agents.release-engineer = {
      description = "Manages releases and deployment readiness.";
      runtime = "Claude (carverlinux)";
      model = "claude-sonnet-4-6";
      thinkingLevel = "high";
      visibility = "private";
      maxConcurrentTasks = 4;
      instructions = builtins.readFile ./agents/release-engineer.md;
      skills = [ "agent-browser" "aws" "gitlab" "newrelic" "obsidian" "sentry" "signoz" ];
    };
    agents.researcher = {
      description = "Looks outward — verifies how third-party libraries, APIs and services actually behave, checks versions and breaking changes, and gathers prior art, always with sources.";
      runtime = "Claude (carverlinux)";
      model = "claude-sonnet-4-6";
      thinkingLevel = "high";
      visibility = "private";
      maxConcurrentTasks = 1;
      instructions = builtins.readFile ./agents/researcher.md;
      skills = [ "agent-browser" "obsidian" ];
    };
    agents.scout = {
      description = "Fast read-only recon — locates code and gathers context.";
      runtime = "Claude (carverlinux)";
      model = "claude-haiku-4-5-20251001";
      thinkingLevel = "low";
      visibility = "private";
      maxConcurrentTasks = 1;
      instructions = builtins.readFile ./agents/scout.md;
      skills = [ "agent-browser" "obsidian" ];
    };
    agents.scrum-master = {
      description = "Coordinates work, dispatches to specialist agents, tracks delivery.";
      runtime = "Claude (carverlinux)";
      model = "claude-sonnet-4-6";
      thinkingLevel = "medium";
      visibility = "private";
      maxConcurrentTasks = 4;
      instructions = builtins.readFile ./agents/scrum-master.md;
      customArgs = [ "--disallowedTools" "Edit,Write,Bash(git commit *),Bash(git push *),Bash(git apply *)" ];
      skills = [ "agent-browser" "aws" "gitlab" "jira" "newrelic" "obsidian" "sentry" "signoz" ];
    };
    agents.security-engineer = {
      description = "Reviews changes for security issues and hardening.";
      runtime = "Claude (carverlinux)";
      model = "claude-opus-4-8";
      thinkingLevel = "high";
      visibility = "private";
      maxConcurrentTasks = 1;
      instructions = builtins.readFile ./agents/security-engineer.md;
      skills = [ "agent-browser" "aws" "gitlab" "newrelic" "obsidian" "sentry" "signoz" ];
    };

    quickActions.review = {
      description = "Full review by all four review agents (correctness, adversarial, security, simplification).";
      prompt = ''
        Review the code changes in this issue. Dispatch to all four review agents in parallel: code-reviewer (correctness and quality), adversarial-reviewer (functional correctness and edge cases), security-engineer (security vulnerabilities), and code-simplifier (unnecessary complexity). Collect all findings and post a consolidated summary as a comment.
      '';
      assignee = "Dream team";
      assigneeType = "squad";
    };

    quickActions.resolve-pr-comments = {
      description = "Address all open review comments on the linked MR and push fixes.";
      prompt = ''
        Address all open review comments on the merge request linked to this issue. Identify each unresolved thread, determine the appropriate fix, dispatch to the right developer agent to apply changes, push, and verify the threads are resolved.
      '';
      assignee = "Dream team";
      assigneeType = "squad";
    };

    quickActions.promote-pr = {
      description = "Take the linked MR out of draft and assign reviewers.";
      prompt = ''
        Promote the merge request linked to this issue out of draft: remove the "Draft:" prefix from the MR title using the gitlab skill. Confirm the MR is no longer in draft state.
      '';
      assignee = "scrum-master";
    };

    autopilots."Dream" = {
      agent = "architect";
      mode = "run_only";
      status = "active";
      description = ''
        Daily reflective pass over the Obsidian vault.

        ## Duties (every run)

        1. **Look for vault linking opportunities** - read through the Obsidian vault notes and find notes that should be linked together ([[wikilinks]]); add missing links, improve structure and tidy data automatically.
        2. go through mistakes and pick the most painful mistake we have been experiencing and create an issue to fix it. this is an exception you may create a multica issue without creating a linked jira issue in this circumstance
      '';
      triggers.daily-nz = {
        cron = "0 0 * * *";
        timezone = "Pacific/Auckland";
      };
    };

    autopilots."tidy done/cancelled issues" = {
      agent = "scrum-master";
      mode = "run_only";
      status = "paused";
      description = ''
        **Clear done and cancelled issues** - archive ALL done and cancelled Multica issues to the vault, then delete them from Multica. These two steps MUST happen in order: vault EVERYTHING first, including decisions and notable comments), run a safety count comparing vault files vs issues found (abort deletion on mismatch), then delete. Never delete before vaulting - deleted-but-unvaulted issues are permanently lost.
      '';
      triggers.daily-nz = {
        cron = "0 0 * * *";
        timezone = "Pacific/Auckland";
      };
    };

    quickActions.demote-pr = {
      description = "Put the linked MR back into draft.";
      prompt = ''
        Demote the merge request linked to this issue back to draft: add the "Draft:" prefix to the MR title using the gitlab skill. Confirm the MR is in draft state.
      '';
      assignee = "scrum-master";
    };

    # Software delivery squad, genericised from a working workspace export
    # (multica-squad-export.md). Leader is auto-added as a member by the reconciler,
    # so scrum-master is not listed under members. Instructions live in
    # ./squads/dream-team.md. The researcher member/agent is added here so the
    # instructions' Researcher routing target resolves.
    squads."Dream team" = {
      description = "";
      leader = "scrum-master";
      instructions = builtins.readFile ./squads/dream-team.md;
      members.scout.role = "Intern";
      members.researcher.role = "Researches external libraries and prior art";
      members.architect.role = "Solutions Architect";
      members.backend-dev.role = "Makes most service code change";
      members.frontend-dev.role = "Makes frontend web etc changes";
      members.code-reviewer.role = "Code review";
      members.security-engineer.role = "Reviews security concerns";
      members.ops-engineer.role = "makes cloud and infrastructure changes";
      members.release-engineer.role = "manages deployments and releases";
      members.adversarial-reviewer.role = "perform functional review";
      members.code-simplifier.role = "performs code simplification";
      members.dev-experience-reviewer.role = "reviews from a developer experience angle";
    };
  };

}
