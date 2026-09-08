---
name: what-now 
description: Asks the agent for recommendation for next steps.
disable-model-invocation: true
---

<task>
  I want to know what are current decissions to make and possible next steps.
  If there are none - say so PLAINLY without side notes.
  Focus on closing the main task for the session (usually defined in one of the first user messages).
</task>

<example-output>
Main task: Implement issue 123 - Example issue title

# Decissions to make

**first decission brief**
First decission explanation. 
Explain why you need support in this decission.
Keep it brief. Provide simple scenario showing why the decission is important.
Outline the options, and their consequences as well as recommendation.

**second decission brief**
...

# Possible next steps
A1: single sentence next step description
A2: ...
...

I recommend **A2** bacause ... (before providing recommendation think about consequences)
</example-output>

<additional-rules>
  - `Decissions to make` section is optional. Only provide it if there are actually some to make.
</additional-rules>




