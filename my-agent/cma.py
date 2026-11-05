#!/usr/bin/env python3
"""Payload builders + response parsing for the launch scripts (python, not jq:
CMA responses embed the system prompt with control characters jq rejects).

  cma.py get <resp.json> <key>[.<key>...]       print a field from a response
  cma.py pick-model <models.json>               newest Opus-class model id
  cma.py agent                                  agent.json with $MODEL filled in
  cma.py kickoff [setup.patch]                  the user.define_outcome event
  cma.py session <title> [setup.patch]          session body (pinned agent, repo, kickoff)
  cma.py deployment                             deployment body (cron + kickoff)
"""
import json, os, sys

DIR = os.path.dirname(os.path.abspath(__file__))
REPO_URL = "https://github.com/shivadeepnoora/launch-your-agent"
SCHEDULE = {"type": "cron", "expression": "0 8 * * 1", "timezone": "Asia/Kolkata"}


def read(name):
    with open(os.path.join(DIR, name)) as f:
        return f.read()


def load(path):
    with open(path) as f:
        return json.JSONDecoder(strict=False).decode(f.read())


def repo_resource():
    res = {"type": "github_repository", "url": REPO_URL,
           "mount_path": "/workspace/launch-your-agent",
           "checkout": {"type": "branch", "name": "main"}}
    if os.environ.get("REPO_TOKEN"):   # only needed if the repo is private
        res["authorization_token"] = os.environ["REPO_TOKEN"]
    return res


def pinned_agent():
    return {"type": "agent", "id": os.environ["AGENT_ID"], "version": int(os.environ["AGENT_VERSION"])}


def kickoff(patch=None):
    task = read("first_prompt.txt")
    if patch:   # eval cases: plant known drift before the audit
        with open(patch) as f:
            task += ("\n\nEVAL SETUP (do this first): save the patch below to /tmp/setup.patch and run "
                     "`git apply /tmp/setup.patch` in /workspace/launch-your-agent, then audit the resulting "
                     "tree (its working copy, not HEAD). fix.patch must apply to that patched tree.\n\n"
                     "```diff\n" + f.read() + "```\n")
    return {"type": "user.define_outcome", "description": task,
            "rubric": {"type": "text", "content": read("outcome.md")}, "max_iterations": 3}


def main(cmd, *args):
    if cmd == "get":
        v = load(args[0])
        for k in args[1].split("."):
            v = v[int(k)] if isinstance(v, list) else v[k]
        print(v if not isinstance(v, (dict, list)) else json.dumps(v, indent=2))
    elif cmd == "pick-model":
        ids = [m["id"] for m in load(args[0])["data"]]   # API lists newest first
        print(next(i for i in ids if "opus" in i))
    elif cmd == "agent":
        a = json.loads(read("agent.json"))
        a["model"] = os.environ["MODEL"]
        print(json.dumps(a))
    elif cmd == "kickoff":
        print(json.dumps(kickoff(*args), indent=2))
    elif cmd == "session":
        print(json.dumps({"agent": pinned_agent(), "environment_id": os.environ["ENV_ID"],
                          "title": args[0], "resources": [repo_resource()],
                          "initial_events": [kickoff(*args[1:])]}))
    elif cmd == "deployment":
        print(json.dumps({"name": "repo-consistency-checker weekly", "agent": pinned_agent(),
                          "environment_id": os.environ["ENV_ID"], "resources": [repo_resource()],
                          "initial_events": [kickoff()], "schedule": SCHEDULE}))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(*sys.argv[1:])
