{smcl}
{title:enumprod}

{pstd}
Compute daily survey productivity by enumerator and supervisor, reshape results, and export to Excel.

{title:Syntax}

{p 8 16 2}
{cmd:enumprod} {it:using filename}, {cmd:starttime(}{it:varname}{cmd:)} {cmd:enum(}{it:varname}{cmd:)} [{cmd:consent(}{it:varname}{cmd:)} {cmd:sup(}{it:varname}{cmd:)}]

{title:Options}

{p 8 16 2}{cmd:starttime()}  
  Required. DateTime or Date variable marking survey start.

{p 8 16 2}{cmd:sup()}  
  Required. Supervisor variable.

{p 8 16 2}{cmd:enum()}  
  Required. Enumerator variable.

{p 8 16 2}{cmd:consent()}  
  Optional. If provided, restricts to cases where {cmd:consent==1}.

{title:Example}

{pstd}
. use survey_data, clear  
. enumprod using "daily_counts.xlsx", starttime(starttime) sup(supervisor_name) enum(enumerator_name) consent(consent)

{title:Saved results}

{pstd}
{cmd:r(outfile)} – path of exported Excel file

{title:Author}

{pstd}
Md. Abu Sayeed

{pstd}
Senior Data Analyst

{pstd}
Email:sayeedahmed880@gmail.com

{pstd}
WhatsApp:01712237013

{pstd}
Development Research Initiative(dRi)

