# infected-data

Data repository and Scalpel - tool that downloads and disects latest RIVM COVID-19 data into mobile friendly files.

## Data
Currently contains only latest numbers (< 24h) separated into files: 
- per region  
`data/latest/region/{region code}.json`. 
- Or a single file grouping specific regions  
 `data/latest/{municipalities|security_regions|provinces|national}.json`. 

## Scalpel
Swift command line tool that creates files in `data` directory.

### How To Use
1. Clone this repository.
1. Navigate to root of this repository.
1. Run `swift run scalpel`.

## License
Data and Scalpel tool are both licensed [CC0](https://creativecommons.org/share-your-work/public-domain/cc0/). Original data is copyright RIVM.
