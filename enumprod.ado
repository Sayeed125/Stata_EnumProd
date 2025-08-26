*! enumprod.ado
*! Enumerator daily productivity (counts per day by enumerator, exported + shown in Results)
*! Version 1.5, Author: Sayeed
version 17.0

program define enumprod, rclass
    // Required options: starttime and enum
    // Optional: sup and consent
    syntax using/, starttime(varname) enum(varname) [sup(varname) consent(varname)]

    local start "`starttime'"
    local sup "`sup'"
    local enum "`enum'"
    local consent "`consent'"

    // Check required variables exist
    foreach v in `start' `enum' {
        capture confirm variable `v'
        if _rc {
            di as err "enumprod: variable `v' not found in dataset"
            exit 198
        }
    }

    // Check optional supervisor variable if provided
    if "`sup'" != "" {
        capture confirm variable `sup'
        if _rc {
            di as err "enumprod: supervisor variable `sup' not found"
            exit 198
        }
    }

    preserve
    quietly {
        // Convert starttime to daily date
        local fmt : format `start'
        local p_tc = strpos("`fmt'","tc")
        local p_td = strpos("`fmt'","td")

        if `p_tc' > 0 {
            gen double fielddate = dofc(`start')
        }
        else if `p_td' > 0 {
            gen double fielddate = `start'
        }
        else {
            capture gen double fielddate = dofc(`start')
            if _rc {
                restore
                di as err "enumprod: cannot convert `start' to daily date. Ensure it's %tc or %td."
                exit 459
            }
        }
        format fielddate %tdDDmonCCYY

        // Apply consent filter if given
        if "`consent'" != "" {
            capture confirm variable `consent'
            if _rc {
                di as err "enumprod: consent variable `consent' not found"
                restore
                exit 198
            }
            keep if `consent' == 1
        }

        // Keep only relevant variables
        if "`sup'" != "" {
            keep `sup' `enum' fielddate
        }
        else {
            keep `enum' fielddate
        }

        // --- Count daily surveys per enumerator ---
        bysort `enum' fielddate: gen daily_count = _N

        // Collapse by supervisor + enumerator + date (or just enumerator if sup missing)
        if "`sup'" != "" {
            collapse (count) daily_count, by(`sup' `enum' fielddate)
        }
        else {
            collapse (count) daily_count, by(`enum' fielddate)
        }

        // Reshape to wide format
        if "`sup'" != "" {
            reshape wide daily_count, i(`sup' `enum') j(fielddate)
        }
        else {
            reshape wide daily_count, i(`enum') j(fielddate)
        }

        // Rename columns to readable date labels
        ds daily_count*
        local oldvars `r(varlist)'
        local newvars ""

        foreach v of local oldvars {
            local num = substr("`v'", 12, .)
            local numval = real("`num'")
            local dlabel : display %tdDDmonCCYY `numval'
            local safe = subinstr("d_`dlabel'", " ", "", .)
            rename `v' `safe'
            label var `safe' "`dlabel'"
            local newvars "`newvars' `safe'"
        }

        // Total surveys per enumerator
        egen total_surveys = rowtotal(`newvars')
        label var total_surveys "Total surveys"

        // Average surveys per day per enumerator
        egen avg_per_day = rowmean(`newvars')
        label var avg_per_day "Avg surveys per day"

        // Reorder columns
        if "`sup'" != "" {
            ds `sup' `enum' total_surveys avg_per_day
        }
        else {
            ds `enum' total_surveys avg_per_day
        }
        local firstvars `r(varlist)'

        ds d_*
        local datevars `r(varlist)'

        order `firstvars' `datevars'

        // Show results
        di as txt "Enumerator daily productivity:"
        list, abbrev(20) noobs

        // Export to Excel
        capture noi export excel using "`using'", ///
            sheet("Daily_survey_by_enum") sheetreplace ///
            firstrow(varlabels) cell(A1)
        if _rc {
            di as err "enumprod: export failed (rc=`_rc'). Check path/permissions."
            restore
            exit 459
        }

        di as txt "enumprod: results also exported to `using'"
        return local outfile "`using'"
    }
end
