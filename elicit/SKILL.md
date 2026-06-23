---
name: elicit
description: Conversational information gathering — discuss open questions with the user one topic at a time instead of dumping a list of questions. The user closes each topic, never the agent. Use this instead of any built-in question or multiple-choice form (e.g. AskUserQuestion) whenever you need a decision or information from the user — even a single question. Use whenever you need several pieces of information or decisions from the user (design choices, requirements, preferences), or one complex topic that deserves a real conversation. Trigger phrases - "elicit", "/elicit", "let's talk this through", "przegadajmy to".
metadata:
  approach: one-topic-at-a-time
---

# Elicit — One Topic at a Time

When you need information from the user, the failure mode is dumping a numbered list of questions and expecting answers to all of them at once. The user often cannot just decide — they need to ask back, learn the implications, exchange a few opinions before a decision is sound. This skill replaces the question dump with a sequence of small conversations.

The core contract: **the user closes a topic, never you.** You may propose closing; you may never advance on your own judgment.

## The Flow

### 1. Agenda

Open with the list of topics you need to discuss — titles only, one line each, no question content yet. This shows the user the scope of the conversation.

Order for human cognitive flow, not for your bookkeeping: related topics go next to each other, so the user never has to drop a mental context and pick it back up later. Within that, put topics whose answers inform later ones first.

The agenda is mutable. If the conversation surfaces a new topic, add it and say so. If an earlier answer makes a topic moot, drop it and say so. If two topics turn out to be one — and only if that is genuinely true — merge them and say so.

A single complex topic is a valid agenda of one. The per-topic rules below still apply.

### 2. One topic, conversationally

Take the first open topic. When you know the total — i.e. the agenda is fixed — **prefix it with its position: "Topic X/Y"** (X = current topic, Y = total), so the user can see how much is left. If the agenda is still open-ended and you cannot yet name Y, skip the counter rather than guess; resume it once the scope is fixed. When the agenda changes mid-conversation (a topic added, dropped, or merged), the counter follows the new total — say so when it shifts.

Open it with context, not a bare question:

- **Why you are asking** — what depends on the answer.
- **What options you see** and what each implies downstream.
- **Your own opinion** — what you would pick and why.

Then ask, openly. This is an exchange of views, not an interrogation: the user reacts to your take, asks back, pushes; you answer their questions, refine, push back when you disagree.

Stay on the current topic by default, but follow the thread, not the list:

- **If the discussion naturally leads into a later agenda item**, take that item next — announce the reorder ("this leads straight into topic 4, let's take it now") instead of snapping back to the original order. Order is in service of context; never make the user drop a train of thought just to honor the list.
- **If the user jumps to another topic**, follow them. The agenda serves the user, not the other way around.
- **If the user's answer touches a later topic in passing**, note it ("that settles part of topic 3") and continue the current one. When you later reach that topic, start from what was already said — summarize it and confirm, do not re-ask from scratch.

### 3. Propose closing

When you believe you understand, **summarize the agreement in 1–2 sentences** and propose closing: "Closing this topic: <summary>. Move on?" The summary is the point — it is the user's chance to catch that you understood something differently than they meant. A bare "can we move on?" without a summary is not acceptable.

**The closing proposal ends your turn.** Nothing comes after "Move on?" — no opening the next topic, no previewing it, no "meanwhile, about topic 2". The next topic starts in a *later* turn, after the user has confirmed. Bundling the proposal with the next topic turns the question into a rhetorical one: you have advanced on your own judgment, exactly what this skill forbids. The cost of one extra turn is the price of the user's control; pay it.

Advance **only** on explicit confirmation ("ok", "next", "yes, move on"). If the user replies with new content instead of confirming, the topic stays open — incorporate it and continue. Never treat silence-adjacent replies ("hm", "maybe") as confirmation.

If the user says to move on while you still lack something, do not silently comply and do not silently assume: say what is missing and that it still needs discussing. The user decides what happens next — but they can only decide about a gap they know exists.

### 4. Repeat, then recap

Work through the agenda topic by topic. After the last topic closes, give a compact recap of **all** agreements — one line per topic. This is the reference point for the work that follows; subsequent implementation should be checkable against it.

## AskUserQuestion: the exception, not the default

The default form is free-form chat. `AskUserQuestion` is allowed only when **the conversation itself has already narrowed the topic** to a concrete pick between 2–4 clear options whose stakes the user already understands. Opening a topic with it is a violation — that is the question dump this skill exists to prevent.

When you do use it:

- **One question per call.** Never bundle several topics into one form.
- **An off-list answer does not close the topic.** If the user picks "Other" or replies with something outside your options, that is new information, not a verdict — return to conversation, ask follow-ups, understand it. The known failure mode is the agent accepting an off-list answer at face value and never asking again; always follow up instead.

## Anti-Patterns To Refuse

- **The question dump.** Listing 4 questions and asking the user to answer all of them. One topic at a time, always.
- **Self-certified understanding.** "I have enough, moving on" without the user's explicit confirmation. The user decides when you have enough.
- **Propose-and-proceed.** "Closing topic 1: <summary>. Move on? — Topic 2: …" in a single message. The question was rhetorical; you advanced before the user answered. The closing proposal must be the last thing in your turn.
- **Closing without a summary.** "Shall we move on?" gives the user nothing to verify. Always restate what you understood first.
- **The survey.** Asking questions without ever sharing your own opinion. The user asked for an exchange of views; give yours and let them react to it.
- **Off-list answer treated as final.** The user answered outside your options and you stopped asking. That answer is the start of the conversation, not the end.
- **Topic drift.** The user's answer mentioned topic 3 in passing while you are on topic 1, so you switch. A passing mention is not a thread — note it, finish the current topic. (Deliberate reordering is different: when the discussion genuinely flows into a later topic, or the user jumps there, follow it — announced, not by accident.)

## Conversation Style

- A few sentences per turn. This is a conversation, not a briefing.
- Concrete proposals with reasons beat open-ended "what do you think?".
- Disagree out loud when you disagree — polite agreement wastes the user's time.
