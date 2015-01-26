# Data Parser for MSP

## Requirements

* CSV should be in UTF-8, and separator `,`
* Preferrably numbers must be in English format (33.2).

## Run

```
bundle
ruby minimal_data_parser.rb
```

Result is generated in `output` folder

# TODO

- [ ] port statistics functionality to new code
- [ ] remove code from old requirements
- [ ] use separate modules for lookup table, averages
- [ ] CSV filter for state, capitalize cells
