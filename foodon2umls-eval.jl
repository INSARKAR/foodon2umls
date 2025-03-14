# calculate performance statistics

function main()

    mapping_file_name = "./mappings/foodon2umls_mapping.psv"

    # example mapping line: D|U>F|FOODON_00002439|endive|C1304560|endive
    
    tp_ols_count = 0
    tp_umlsapi_count = 0
    tp_total_count = 0

    fp_total_count = 0
    fp_ols_count = 0


    # read in the mapping file
    for line in readlines(open(mapping_file_name, "r"))

        line_parts = split(line, "|")

        mapping_result = line_parts[1]
        mapping_type = line_parts[2]
        foodon_id = line_parts[3]
        foodon_term = line_parts[4]
        umls_cui = line_parts[5]
        umls_term = line_parts[6]


        
    end
end