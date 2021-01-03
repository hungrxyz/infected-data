# infected-data

Data repository and Scalpel - tool that downloads and disects latest RIVM COVID-19 data into mobile friendly files.

## Data
Currently contains only latest numbers (< 24h) separated into files: 
- per region  
`data/latest/region/{region code}.json`. 
- Or a single file grouping specific regions  
 `data/latest/{municipalities|security_regions|provinces|national}.json`.

 ### Sources
 - [RIVM](https://data.rivm.nl/covid-19/COVID-19_aantallen_gemeente_per_dag.csv) - confirmed cases and deaths for all regions.
 - [RIVM + NICE](https://data.rivm.nl/geonetwork/srv/dut/catalog.search#/metadata/4f4ad069-8f24-4fe8-b2a7-533ef27a899f) - hospitalizations.
 - [NICE](https://stichting-nice.nl/covid-19/public/new-intake/confirmed) - national new intensive care admissions.
 - [LCPS](https://lcps.nu/wp-content/uploads/covid-19.csv) - national currently occupied hospital and intensive care beds.
 - [CBS](https://opendata.cbs.nl/#/CBS/nl/dataset/84721NED/table?dl=3A154) - region codes and population for all regions.

## Scalpel
Swift command line tool that creates files in `data` directory.

### How To Use
1. Clone this repository.
1. Navigate to root of this repository.
1. Run `swift run scalpel`.

## License
Data and Scalpel tool are both licensed [CC0](https://creativecommons.org/share-your-work/public-domain/cc0/). Original data is copyright RIVM, NICE, LCPS and CBS.
