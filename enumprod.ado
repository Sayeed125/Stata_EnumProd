*! enumprod.ado
*! Enumerator daily productivity (counts per day by enumerator, exported + shown in Results)
*! Version 1.1, Author: Sayeed
version 17.0

program define enumprod, rclass
    // Required options
    syntax using/, starttime(varname) sup(varname) enum(varname) [consent(varname)]

    local start "`starttime'"
    local sup "`sup'"
    local enum "`enum'"
    local consent "`consent'"

    // check variables exist
    foreach v in `start' `sup' `enum' {
        capture confirm variable `v'
        if _rc {
            di as err "enumprod: variable `v' not found in dataset"
            exit 198
        }
    }

    preserve
    quietly {
        // Convert starttime → daily date
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

        // Keep vars of interest
        keep `sup' `enum' fielddate

        // Daily counts per enumerator
        bysort `enum' fielddate: gen daily_average = _N
        collapse (count) daily_average, by(`sup' `enum' fielddate)
        reshape wide daily_average, i(`sup' `enum') j(fielddate)

        // Rename date columns
        ds daily_average*
        local vars `r(varlist)'
        foreach v of local vars {
            local d = substr("`v'",14,.)
            local dlabel : display %tdDDmonCCYY `d'
            local safe = subinstr("d_`dlabel'"," ","",.)
            local safe = subinstr("`safe'","/","_",.)
            local safe = subinstr("`safe'","-","_",.)
            rename `v' `safe'
            label var `safe' "`dlabel'"
        }
    }

    // Show results in Results window
    di as txt "Enumerator daily productivity:"
    list, abbrev(20) noobs

    // Export to Excel
    capture noi export excel using "`using'", ///
        sheet("Daily_survey_by_enum") sheetreplace firstrow(varlabels) cell(A1)
    if _rc {
        di as err "enumprod: export failed (rc=`_rc'). Check path/permissions."
        restore
        exit 459
    }

    // Keep reshaped dataset in memory (not restoring original)
    di as txt "enumprod: results also exported to `using'"
    return local outfile "`using'"
end
