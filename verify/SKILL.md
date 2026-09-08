---
name: verify 
argument-hint: "Which PR?"
description: Verifies that the change in PR is ready to merge.
disable-model-invocation: true
---

<task>
  Make sure that the PR is ready to merge. It means that:
  - code has been reviewed with /code-review skill and the last round didn't yield any significant problems
  - ticket acceptance criteria are met
  - implemented feature was tested and works as expected and described within the issue
  - PR checks are green
  - all comments are adressed
  - additional task-specific requirements are met
  - comments are minimal, clean and don't contain irrelevant facts or stories
</task>


<output-rules>
  - for each verified thing output single line like: "code review: done (3 rounds)" or "acceptance criteria met"
  - DO NOT dive into the details, provide overview of eventual problems/unmet requirements - the user will ask for details if necessary
</output-rules>

<example-output>
PR is **ready** to be merged:
- code review: done (3 rounds)
- all acceptance criteria met
- feature was tested successfully
- all PR checks are green
</example-output>

<example-output>
PR is **not ready** to merge:
- code review: done (3 rounds)
- all acceptance criteria met
- feature tested successfully
- PR checks - pending 

What's left?

**single line summary**

longer explanation and next steps...

**another thing**

explanation...

...

</example-output>

