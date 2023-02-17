If you follow the instructions in `installation` section, things should be working. Here is a little more information about what is going on behind the scenes. You can customize any of the default filter behavior. 

## Users hits `Apply`
If you use the `filter_builder_dropdown` helper partial, when the user hits Apply a few things happen. 
1. A request is sent to the gem which validates the filter input
2. If the filter passes validation, a `turbo-stream` is sent which emits a ` @filter_submit_success` event which includes a `stable_id` and a `url`. 
3. The `filter_builder_dropdown` partial listens for this event, and on success runs the `loadResults` stimulus action. 
4. `loadResults` automatically pushes to the new URL, which is the old URL + stable_id parameter

