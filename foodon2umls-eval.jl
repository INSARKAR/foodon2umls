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

function fpr(fp, tn)
    return fp / (fp + tn)
end

function tnr(tn, fp)
    return tn / (tn + fp)
end

function ba(tpr, tnr)
    return (tpr + tnr) / 2
end


function main()

    mapping_file_name = "./mappings/foodon2umls_mapping.psv"

    umls_sab_dict = Dict{String, Set{String}}()

    umls_mrconso_file_name = "./umls/2024AB/META/MRCONSO.RRF"

    println("loading UMLS MRCONSO file...")
    
    for line in readlines(open(umls_mrconso_file_name, "r"))
        line_parts = split(line, "|")
        umls_cui = line_parts[1]
        umls_sab = line_parts[12]
        #umls_sab_dict[umls_cui] = umls_sab

        if !haskey(umls_sab_dict, umls_cui)
            # println("adding $umls_cui to umls_sab_dict")
            umls_sab_dict[umls_cui] = Set{String}()
            umls_sab_dict[umls_cui] = push!(umls_sab_dict[umls_cui], umls_sab)
        else
            # println("adding $umls_sab to umls_sab_dict[$umls_cui]")
            umls_sab_dict[umls_cui] = push!(umls_sab_dict[umls_cui], umls_sab)
        end
    end

    # # umls_sab_file 
    # umls_sab_file_name = "./src_terms/umls_food_sources.psv"

    # for line in readlines(open(umls_sab_file_name,"r"))
    #     line_parts = split(line, "|")
    #     umls_cui = line_parts[1]
    #     umls_sab = line_parts[2]

    #     # println("$umls_cui|$umls_sab")


    #     if !haskey(umls_sab_dict, umls_cui)
    #         # println("adding $umls_cui to umls_sab_dict")
    #         umls_sab_dict[umls_cui] = Set{String}()
    #         umls_sab_dict[umls_cui] = push!(umls_sab_dict[umls_cui], umls_sab)
    #     else
    #         # println("adding $umls_sab to umls_sab_dict[$umls_cui]")
    #         umls_sab_dict[umls_cui] = push!(umls_sab_dict[umls_cui], umls_sab)
    #     end

    # end

    # example mapping line: D|U>F|FOODON_00002439|endive|C1304560|endive
   
    tp_direct_count = 0

    tp_total_count = 0
    tp_ols_count = 0
    tp_umlsapi_count = 0

    fp_total_count = 0
    fp_ols_count = 0
    fp_umlsapi_count = 0

    tn_total_count = 0
    tn_ols_count = 0
    tn_umlsapi_count = 0

    foodon_id_set = Set{String}()
    umls_id_set = Set{String}()

    ols_count = 0
    umls_count = 0

    umls_sab_count_dict = Dict{String, Int}()

    # read in the mapping file
    for line in readlines(open(mapping_file_name, "r"))

        line_parts = split(line, "|")

        mapping_result = line_parts[1]
        mapping_type = line_parts[2]
        foodon_id = line_parts[3]
        foodon_term = line_parts[4]
        umls_cui = line_parts[5]
        umls_term = line_parts[6]

        foodon_id_set = push!(foodon_id_set, foodon_id)
        umls_id_set = push!(umls_id_set, umls_cui)

        if mapping_type == "U>F"
            ols_count += 1
        elseif mapping_type == "F>U"
            umls_count += 1
        end

        if mapping_result == "D"

            tp_direct_count += 1

            # lookup the SAB for the UMLS concept
            umls_sab_set = umls_sab_dict[umls_cui]

            for umls_sab in umls_sab_set

                if haskey(umls_sab_count_dict, umls_sab)
                    umls_sab_count_dict[umls_sab] += 1
                else
                    umls_sab_count_dict[umls_sab] = 1
                end

            end
            # if haskey(umls_sab_count_dict, umls_sab)
            #     println("adding 1 to $umls_sab")
            #     umls_sab_count_dict[umls_sab] += 1
            # else
            #     println("starting with 1 in $umls_sab")
            #     umls_sab_count_dict[umls_sab] = 1
            # end

        end

        if mapping_result == "O"

            tp_ols_count += 1

            # lookup the SAB for the UMLS concept
            umls_sab_set = umls_sab_dict[umls_cui]

            for umls_sab in umls_sab_set

                if haskey(umls_sab_count_dict, umls_sab)
                    umls_sab_count_dict[umls_sab] += 1
                else
                    umls_sab_count_dict[umls_sab] = 1
                end

            end

            # if haskey(umls_sab_count_dict, umls_sab)
            #     umls_sab_count_dict[umls_sab] += 1
            # else
            #     umls_sab_count_dict[umls_sab] = 1
            # end

        end

        if mapping_result == "U"

            tp_umlsapi_count += 1

            # lookup the SAB for the UMLS concept
            umls_sab_set = umls_sab_dict[umls_cui]

            for umls_sab in umls_sab_set

                if haskey(umls_sab_count_dict, umls_sab)
                    umls_sab_count_dict[umls_sab] += 1
                else
                    umls_sab_count_dict[umls_sab] = 1
                end

            end
            # if haskey(umls_sab_count_dict, umls_sab)
            #     umls_sab_count_dict[umls_sab] += 1
            # else
            #     umls_sab_count_dict[umls_sab] = 1
            # end

        end

        if mapping_result == "X"


            if mapping_type == "U>F"
                fp_ols_count += 1
            elseif mapping_type == "F>U"
                fp_umlsapi_count += 1
            end

        end
      
    end

    tp_ols_count = tp_ols_count - tp_direct_count
    tp_umlsapi_count = tp_umlsapi_count - tp_direct_count

    tp_total_count = tp_direct_count + tp_ols_count + tp_umlsapi_count
    fp_total_count = fp_ols_count + fp_umlsapi_count

    tn_ols_count = ols_count - tp_ols_count - fp_ols_count
    tn_umlsapi_count = umls_count - tp_umlsapi_count - tp_umlsapi_count
    tn_total_count = (tn_ols_count + tn_umlsapi_count)

    total_pr = pr(tp_total_count, fp_total_count)
    total_fpr = fpr(fp_total_count, tn_total_count)
    total_tnr = tnr(tn_total_count, fp_total_count)
    total_ba = ba(total_pr, total_tnr)
    #total_rc = rc(tp_total_count, fn_total_count)
    #total_f1 = f1(total_pr, total_rc)

    u2f_pr = pr(tp_ols_count, fp_ols_count)
    u2f_fpr = fpr(fp_ols_count, tn_ols_count)
    u2f_tnr = tnr(tn_ols_count, fp_ols_count)
    u2f_ba = ba(u2f_pr, u2f_tnr)
    #u2f_rc = rc(tp_ols_count, fn_ols_count)
    #u2f_f1 = f1(u2f_pr, u2f_rc)

    f2u_pr = pr(tp_umlsapi_count, fp_umlsapi_count)
    f2u_fpr = fpr(fp_umlsapi_count, tn_umlsapi_count)
    f2u_tnr = tnr(tn_umlsapi_count, fp_umlsapi_count)
    f2u_ba = ba(f2u_pr, f2u_tnr)

    #f2u_rc = rc(tp_umlsapi_count, fn_umlsapi_count)
    #f2u_f1 = f1(f2u_pr, f2u_rc)

    output_file_name = "./foodon2umls_mapping_performance.txt"
    output_file = open(output_file_name, "w")

    println(output_file, ">> $ols_count OLS (U>F) mappings attempted")
    println(output_file, ">> $umls_count UMLS (F>U) API mappings attempted")
    println(output_file, "")

    println(output_file, "Performance statistics for foodon2umls mapping ($(length(foodon_id_set)) foodon terms)")
    println(output_file, "")

    println(output_file, "Total TP: ", tp_total_count)
    println(output_file, "Total FP: ", fp_total_count)
    println(output_file, "Total TN: ", tn_total_count)
    println(output_file, "")

    println(output_file, "OLS TP: ", tp_ols_count)
    println(output_file, "OLS FP: ", fp_ols_count)
    println(output_file, "OLS TN: ", tn_ols_count)
    println(output_file, "")

    println(output_file, "UMLS API TP: ", tp_umlsapi_count)
    println(output_file, "UMLS API FP: ", fp_umlsapi_count)
    println(output_file, "UMLS API TN: ", tn_umlsapi_count)
    println(output_file, "")

    println(output_file, "Total Precision: ", total_pr)
    println(output_file, "Total False Positive Rate: ", total_fpr)
    println(output_file, "Total True Negative Rate: ", total_tnr)
    println(output_file, "Total Balanced Accuracy: ", total_ba)
    # println("Total Recall: ", total_rc)     
    # println("Total F1 Score: ", total_f1)
    println(output_file, "")

    println(output_file, "OLS Precision: ", u2f_pr)
    println(output_file, "OLS False Positive Rate: ", u2f_fpr)
    println(output_file, "OLS True Negative Rate: ", u2f_tnr)
    println(output_file, "OLS Balanced Accuracy: ", u2f_ba)
    # println("OLS Recall: ", u2f_rc)
    # println("OLS F1 Score: ", u2f_f1)
    println(output_file, "")

    println(output_file, "UMLS API Precision: ", f2u_pr)
    println(output_file, "UMLS API False Positive Rate: ", f2u_fpr)
    println(output_file, "UMLS API True Negative Rate: ", f2u_tnr)
    println(output_file, "UMLS API Balanced Accuracy: ", f2u_ba)
    # println("UMLS API Recall: ", f2u_rc)
    # println("UMLS API F1 Score: ", f2u_f1)
    println(output_file, "")


    println(output_file, "UMLS SAB Counts")
    for (umls_sab, count) in umls_sab_count_dict
        println(output_file, "$umls_sab|$count")
    end

    close(output_file)

end

main()