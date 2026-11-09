# /power-architect:finish

Adapted from Superpowers `finishing-a-development-branch`. Announce: "I'm finishing this development branch."

1. **Verify tests.** Run the full suite. If anything fails, report the failures and stop; the options come only after a green suite.
2. **Detect the environment.** Capture `GIT_DIR`, `GIT_COMMON` (`git rev-parse --git-dir` / `--git-common-dir`, resolved to absolute paths), and `WORKTREE_PATH` (`git rev-parse --show-toplevel`) *now*, before changing directory.
   - Normal repo, or a worktree on a named branch → 3 options.
   - Detached HEAD → 2 options (no merge); the workspace is externally managed.
3. **Determine the base branch** the work forked from. If it isn't known, ask: "This branch split from <guess> — is that correct?"
4. **Present exactly these options** and wait. Integration is the user's decision.

   ```
   Implementation complete. What would you like to do?

   1. Merge back to <base-branch> locally
   2. Push and create a Pull Request
   3. Keep the branch as-is (I'll handle it later)

   Which option?
   ```

   For a detached HEAD: 1. Push as a new branch and create a PR · 2. Keep as-is.
5. **Execute the choice.**
   - **Merge:** from the main repo root, `git checkout <base>`, `git pull`, `git merge <branch>`, then run the tests **on the merged result**. If they fail, stop and leave the branch and worktree in place. If they're green, clean up the worktree (step 6), then `git branch -d <branch>`.
   - **PR:** `git push -u origin <branch>`, then open the PR with the forge's tooling, following the repo's PR template, and report the URL. **Keep the worktree** for PR feedback.
   - **Keep:** report "Keeping branch <name>. Worktree preserved at <path>."
   - **Discard** happens only if the user explicitly asks. List the branch, commits, and worktree that will be deleted, and require them to type `discard`. Then clean up and `git branch -D`.
6. **Clean up** (merge or confirmed discard only). For a normal repo there's nothing to do. A worktree under `.worktrees/` or `worktrees/` is ours: `git worktree remove "$WORKTREE_PATH" && git worktree prune`. If removal is refused because of uncommitted files, **never use `--force`**: show the files and ask whether to commit, move, or delete them. Any other worktree belongs to the host, so leave it.

Never force-push unless the user explicitly asks. A rejected push means the remote moved, so investigate.

Then recommend `/power-architect:retro` (optional).
