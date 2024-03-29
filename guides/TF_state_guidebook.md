TF-states are a series of boolean states, i.e., they only contains `true` or `false`.  
In this template, we prefer the **built-in grouping system** for it.  
Before starting working on your TF-states for `Nodes`, it is better to learn about the naming style of them in this template and obey it, and learn how it works in detail.  
**(Note: This only adopts to `Node`. For more generic situation, such as `RefCounted` or even `Object`, please use metadata or create a custom class to manage them)**

## Naming rules
### The basic rule
* All states should begin with "state_", e.g. "state_my_state", "state_A".
* If the name of state contains lexical verbs, turn them into -ing forms. E.g. "state_turning_back", "state_working".
* Continuing the previous one, if the state is a past tense or a kind of status, then use -ed forms; if the state is about a passive action going on, use "being" + -ed forms. E.g. "state_being_attacked", "state_defensed".
* Continuing, again, the previous one, if the state is about to come true, use "to_be". E.g. "state_to_be_working"
* In principle, the modal verbs is not allowed to use for naming states.
* Prepositional and adjective phrases is allowed as well. E.g. "state_on_wall", "state_in_progress".

### Naming with objects
* Unless the state is applied for certain or general objects, we advise to add the object name between the verb/noun and the prefix "state". E.g. "state_goomba_walking", "state_chip_jumping"
* In case a state name not including the object name has the same verb as one with object name, we, by default, regard the former as general state, while the latter one is regarded as a special and specific state for a certain type of objects. E.g. "state_jumping" is used for almost all objects that have this action, while "state_spring_jumping" describes that the spring has a special jumping action that differs from those general items.

## Operation
### The basic principle
We do not add initial states for a node unless we need them.

### Steps
* To add a state, call `<some_node>.add_to_group("state_xxx")`
* To remove a state, call `<some_node>.remove_from_group("state_xxx")`
* To check if a node has some state, call `<some_node>.is_in_group("state_xxx")`
* For multiple operations mentioned above in few steps, you can use `Array`s + `for`-loops, or write a script class to add such methods.
