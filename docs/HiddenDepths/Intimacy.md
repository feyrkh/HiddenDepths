A measure of how comfortable an NPC is with the player. It consists of these numbers - 
- base intimacy - this number is slow to rise or fall, but the momentary intimacy tends to revert back to this number
- momentary intimacy - this number is easily affected by player actions, and is the effective intimacy that's used to determine how an NPC can assist in player rituals
- intimacy decay - this number increases over time, but is easily reduced if the player doesn't ignore the NPC
- embarrassment - this number increases when you exceed an NPC's momentary intimacy threshold during a ritual

## Intimacy cycle
All values start at 0 at the beginning of the game. Player actions increase momentary intimacy, but it resets to base intimacy each day. At the end of the day, a random number of up to the momentary intimacy is chosen - if the number is greater than the base intimacy, the base intimacy increases by a small amount.

At the end of the day, a random number up to the base intimacy is chosen. If the number is less than the intimacy decay, base intimacy will fall by a small amount. If the player has not interacted with an NPC on that day, that NPC's intimacy decay increases by a small amount, but no higher than the base intimacy.

Interactions with characters reduce intimacy decay by a decent amount. Chatting every day is generally enough to keep intimacy decay to a minimum.

During a [[Rituals|Ritual]], you may temporarily increase an NPC's momentary intimacy by playing minigames. Doing this increase the NPC's embarrassment by an equal amount, and embarrassment is subtracted from an NPC's momentary intimacy. Embarrassment slowly decays over time. Additional intimacy decay rolls are made if embarrassment is not zero.

## Using intimacy
The player designs [[Rituals]] to produce certain effects. One component of the ritual is a list of intimate actions required to reach the effect. An NPC assistant is required for most actions, and you need a certain level of intimacy with them to select an action. When designing a ritual, the NPC's current intimacy is shown, along with the level needed for the current action. You can design a ritual that requires more intimacy than you have with a character, but whenever it's time to take an action that you don't have enough intimacy for, you must play a minigame to temporarily increase intimacy, which also increases embarrassment. Failing to raise intimacy enough will cause the ritual to fail as the NPC refuses to continue, 