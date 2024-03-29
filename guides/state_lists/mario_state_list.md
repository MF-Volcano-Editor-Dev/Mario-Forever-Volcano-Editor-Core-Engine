# Mario states

## state_climbable

In this state, the character is able to climb on something climbable. See [state_climbable](#state_climbing).

## state_climbing

The character is climbing on something.  
When the character leaves from climable area, both the `state_climable` and `state_climbing` will be removed from it.

## state_crouching

The character is crouching.

## state_completed

The character has completed the level.  
This will stops the player from controlling the character.

## state_running

The character is running.

## state_turning_back

The character is turning back during horizontal movement.

## state_swimming

The character is swimming.  
Do NOT make the character turn into this state externally, unless you know its functionality.

## state_swimming_to_jumping

The character is able to jump out of the water while swimming.  
Do NOT make the character turn into this state externally, unless you know its functionality.
