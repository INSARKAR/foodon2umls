# calculate performance statistics

function pr(tp, fp)
    return tp / (tp + fp)
end

function rc(tp, fn)
    return tp / (tp + fn)
end

function f1(pr, rc)
    return 2 * pr * rc / (pr + rc)
end

function main()

    mapping_file_name = "./mappings/foodon2umls_mapping.psv"

    # example mapping line: D|U>F|FOODON_00002439|endive|C1304560|endive
    
    tp_total_count = 0
    tp_ols_count = 0
    tp_umlsapi_count = 0

    fp_total_count = 0
    fp_ols_count = 0
    fp_umlsapi_count = 0

    fn_total_count = 0
    fn_ols_count = 0
    fn_umlsapi_count = 0



    # read in the mapping file
    for line in readlines(open(mapping_file_name, "r"))

        line_parts = split(line, "|")

        mapping_result = line_parts[1]
        mapping_type = line_parts[2]
        foodon_id = line_parts[3]
        foodon_term = line_parts[4]
        umls_cui = line_parts[5]
        umls_term = line_parts[6]

        if mapping_result == "D"

            tp_total_count += 1

            if mapping_type == "U>F"
                tp_ols_count += 1
            elseif mapping_type == "F>U"
                tp_umlsapi_count += 1
            end
        end

        if mapping_result == "O"

            tp_total_count += 1
            tp_ols_count += 1
        end

        if mapping_result == "U"

            tp_total_count += 1
            tp_umlsapi_count += 1
        end

        if mapping_result == "N"

            fn_total_count += 1

            if mapping_type == "U>F"
                fn_ols_count += 1
            elseif mapping_type == "F>U"
                fn_umlsapi_count += 1
            end
        end

        if mapping_result == "X"

            fp_total_count += 1

            if mapping_type == "U>F"
                fp_ols_count += 1
            elseif mapping_type == "F>U"
                fp_umlsapi_count += 1
            end

        end
      
    end

    total_pr = pr(tp_total_count, fp_total_count)
    total_rc = rc(tp_total_count, fn_total_count)
    total_f1 = f1(total_pr, total_rc)

    u2f_pr = pr(tp_ols_count, fp_ols_count)
    u2f_rc = rc(tp_ols_count, fn_ols_count)
    u2f_f1 = f1(u2f_pr, u2f_rc)

    f2u_pr = pr(tp_umlsapi_count, fp_umlsapi_count)
    f2u_rc = rc(tp_umlsapi_count, fn_umlsapi_count)
    f2u_f1 = f1(f2u_pr, f2u_rc)

    println("Total TP: ", tp_total_count)
    println("Total FP: ", fp_total_count)
    println("Total FN: ", fn_total_count)
    println()

    println("OLS TP: ", tp_ols_count)
    println("OLS FP: ", fp_ols_count)
    println("OLS FN: ", fn_ols_count)
    println()

    println("UMLS API TP: ", tp_umlsapi_count)
    println("UMLS API FP: ", fp_umlsapi_count)
    println("UMLS API FN: ", fn_umlsapi_count)
    println()

    println("Total Precision: ", total_pr)
    println("Total Recall: ", total_rc)     
    println("Total F1 Score: ", total_f1)
    println()

    println("UMLS API Precision: ", f2u_pr)
    println("UMLS API Recall: ", f2u_rc)
    println("UMLS API F1 Score: ", f2u_f1)
    println()

    println("OLS Precision: ", u2f_pr)
    println("OLS Recall: ", u2f_rc)
    println("OLS F1 Score: ", u2f_f1)
    println()
end

main()