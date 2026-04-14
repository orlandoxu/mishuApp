# Voice AI Core Implementation Plan

## 1. Goal
Build a complete voice-driven AI core workflow for MishuApp:
1. User voice/text input enters one unified pipeline.
2. AI performs intent routing.
3. Pipeline executes one of multiple actions with safe fallbacks.
4. System supports follow-up turns for confirmation/modification/supplement.
5. Memory storage and retrieval are integrated with local vector DB + backend ingest.

## 2. Scope
In scope for this delivery:
1. Intent routing for `store/retrieve/amend/clarify/chat/unknown`.
2. Multi-turn pending-state management.
3. Candidate selection for memory amendment (e.g. "第2条").
4. Clarification and supplement follow-up handling.
5. Backward compatibility with old intent JSON schema.
6. Unit tests for critical text-rule parsing and intent fallback logic.

Out of scope for this delivery:
1. Long-term cloud conversation memory synchronization protocol.
2. True in-place update of historical vector row (currently append revised record).
3. End-to-end device audio acceptance test automation.

## 3. Architecture Decisions
1. Subtraction-first: replace scattered if-chain with a single route executor.
2. Add one actor-based session store for per-user pending conversation states.
3. Keep existing API clients unchanged; extend orchestration layer only.
4. Keep old schema fields (`should_store`, `should_retrieve`) for compatibility.
5. Use Doubao structured extraction for follow-up intent/selection/content to avoid keyword hardcoding.

## 4. Delivery Checklist
- [x] Route executor in `VoiceMemoryPipeline`.
- [x] Pending state actor (`VoiceMemorySessionStore`) with TTL expiration.
- [x] Pending states:
  - [x] awaiting clarification
  - [x] awaiting store supplement
  - [x] awaiting amend selection
  - [x] awaiting amend content
- [x] Selection index extraction by Doubao structured JSON (`selected_index`).
- [x] Amendment/supplement compose helpers.
- [x] Intent schema compatibility fallback.
- [x] Unit tests expanded.
- [x] TODO-AI scan after completion.

## 5. Test Plan
1. Unit: `MemoryIntentPlanTests`
   - parse new schema
   - fallback retrieve
   - fallback amend
   - parse old schema compatibility
2. Unit: `VoiceTurnTextRulesTests`
   - clarification merge
3. Build/test command baseline:
   - `xcodebuild test -project MishuApp.xcodeproj -scheme MishuApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' -only-testing:MishuAppTests/MemoryIntentPlanTests -only-testing:MishuAppTests/VoiceTurnTextRulesTests`

## 6. Current Risks and Follow-ups
1. Simulator test link currently depends on missing UMeng frameworks in local environment.
2. IoT true acceptance remains real-device only by project constraints.
3. Next iteration can add explicit command intents (e.g. reminder schedule parsing).

## 7. Constitution Check (Subtraction First)
1. What was removed:
   - Repetitive serial if-branches in the pipeline were replaced by a single intent route switch.
2. What new states were added and why not computed-only:
   - Added pending conversational states because they are cross-turn runtime context; they cannot be derived from a single latest utterance without losing correctness.
