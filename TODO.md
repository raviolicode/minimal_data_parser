# TODO

1. Refactor summary data, it should have its own class at least.
A separate YAML with the summary data would be nice.

2. Remove from stats everything under 'estructura' because it doesn't have numerical data.
Probably have a `@non_data_criteria` array for `DataParser`, end don't calculate stats for those.

