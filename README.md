## Usage

```stata
. use survey_data, clear
. enumprod using "daily_counts.xlsx", starttime(starttime) sup(supervisor_name) enum(enumerator_name) consent(consent)
# Stata_EnumProd
Stata package to compute daily enumerator productivity and export to Excel
