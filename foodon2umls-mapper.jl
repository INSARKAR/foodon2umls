using FilePathsBase
using HTTP
using JSON


function main()

    # Create the directory if it does not already exist
    map_dir_path = "mappings"
    if !isdir(map_dir_path)
        mkdir(map_dir_path)
    end

    # Define the file paths
    src_dir = "src_terms"

    # Define the file paths
    foodon_terms_file = joinpath(src_dir, "foodon_terms.psv")
    umls_food_items_file = joinpath(src_dir, "umls_food_items.psv")

    # Check if the files exist
    if isfile(foodon_terms_file) && isfile(umls_food_items_file)
        println("Files already exist. Skipping fetch.")
    else
        println("Files do not exist. Need to run foodon2umls-term_retriever.jl first.")
    end

    # Define the output file path for the mapping and non-mapping files
    foodon2umls_mapping_file_name = joinpath(map_dir_path, "foodon2umls_mapping.psv")


    # foodon2umls_no_mapping_file_name = joinpath(map_dir_path, "foodon2umls_no_mapping.psv")
    # foodon2umls_no_mapping_file = open(foodon2umls_no_mapping_file_name, "w")


    # Define the dictionary to store the mappings
    foodon2umls_mapping = Dict{String, String}()

    # Create a set to keep track of FoodOn IDs

    # Load the foodon terms into a dictionary
    foodon_terms = Dict{String, String}()
    open(foodon_terms_file, "r") do file
        for line in eachline(file)
            foodon_id, term = split(line, '|')
            term = lowercase(term)

            # from the pattern 06200 - garden peas (with pods) (efsa foodex2)
            # remove the five digit number the space the dash, and the (efsa foodex2) at the end)
            term = replace(term, r"^\d{5} - " => "")
            term = replace(term, r" \(efsa foodex2\)$" => "")

            # from pattern margarine (dietary)
            # remove the (dietary) at the end
            term = replace(term, r" \(dietary\)$" => "")

            foodon_terms[term] = foodon_id
        end
    end

    # determine count of the number of keys in foodon_terms
    foodon_terms_count = length(foodon_terms)
    println("$foodon_terms_count FoodOn terms loaded.")


    # Load the umls terms into a dictionary
    umls_terms = Dict{String, String}()
    open(umls_food_items_file, "r") do file
        for line in eachline(file)
            cui, term = split(line, '|')
            term = lowercase(term)

            # from pattern cassava - dietary
            # remove the - dietary at the end
            term = replace(term, r" - dietary$" => "")

            # from pattern margarine (dietary)
            # remove the (dietary) at the end
            term = replace(term, r" \(dietary\)$" => "")

            umls_terms[term] = cui
        end
    end

    # determine count of the number of keys in umls_terms
    umls_terms_count = length(umls_terms)
    println("$umls_terms_count UMLS terms loaded.")

    #exit()


    # create set to keep track of non-mapped terms
    non_mapped_terms = Set{String}()

    # Initialize the counter
    counter = 0

    # Create a set to keep track of FoodOn IDs
    processed_foodon_ids = Set{String}()


    # If the mapping file exists, read in the UMLS CUIs into a set
    mapped_umls_cuis = Set{String}()
    if isfile(foodon2umls_mapping_file_name)
        open(foodon2umls_mapping_file_name, "r") do file
            for line in eachline(file)
                parts = split(line, '|')
                umls_cui = parts[5]
                push!(mapped_umls_cuis, umls_cui)

                foodon_id = parts[3]
                push!(processed_foodon_ids, foodon_id)

            end
        end
    end

    # determine count of the number of keys in mapped_umls_cuis
    mapped_umls_cuis_count = length(mapped_umls_cuis)
    println("$mapped_umls_cuis_count UMLS CUIs already mapped.")


    foodon2umls_mapping_file = open(foodon2umls_mapping_file_name, "a")

    if mapped_umls_cuis_count != mapped_umls_cuis_count
    


        # Iterate over the UMLS terms and find direct mappings (UMLS term == FoodOn term)
        for (umls_term, umls_cui) in umls_terms

            counter += 1

            if umls_cui in mapped_umls_cuis
                # println("S $counter Skipping already mapped UMLS Term [CUI]: $umls_term [$umls_cui]")
                continue
            end

            # println("Processing UMLS term: $umls_term")

            # direct mappings
            if haskey(foodon_terms, umls_term)
                println("D $counter / $umls_terms_count Found direct mapping for term (U>F): $umls_term")
                foodon2umls_mapping[foodon_terms[umls_term]] = umls_cui
                print(foodon2umls_mapping_file, "D|U>F|$(foodon_terms[umls_term])|$umls_term|$umls_cui|$umls_term\n")
                # exit()
            else
                #println("No direct mapping found for term (U>F): $umls_term")

                # Send the term to OLS to search the FoodOn ontology


                # Encode the term to be URL-safe
                encoded_umls_term = HTTP.escape(umls_term)

                ols_url = "https://www.ebi.ac.uk/ols4/api/search?q=$encoded_umls_term&ontology=foodon"


                response = HTTP.get(ols_url)

                if response.status == 200
                    results = JSON.parse(String(response.body))
                    if !isempty(results["response"]["docs"])
                        first_result = results["response"]["docs"][1]
                        foodon_id = first_result["short_form"]
                        foodon_term = first_result["label"]
                        println("O $counter / $umls_terms_count Found OLS mapping for term (U>F): $umls_term -> $foodon_term [$foodon_id]")
                        foodon2umls_mapping[foodon_id] = umls_cui
                        print(foodon2umls_mapping_file, "O|U>F|$foodon_id|$foodon_term|$umls_cui|$umls_term\n")
                        #exit()
                    else
                        println("N $counter / $umls_terms_count No OLS mapping found for term (U>F): $umls_term")
                        print(foodon2umls_mapping_file, "N|U>F|||$umls_cui|$umls_term\n")
                    end
                else
                    println("N $counter / $umls_terms_count Failed to query OLS for term (U>F): $umls_term")

                    print(foodon2umls_mapping_file, "N|U>F|||$umls_cui|$umls_term\n")
                    push!(non_mapped_terms, umls_term)
                    # exit()
                end


            end

        end
    else
        println("All (U>F) terms have been mapped.")
    end


    counter = 0

    # Iterate over the FoodOn terms and find mappings using UMLS API
    for (foodon_term, foodon_id) in foodon_terms

        counter += 1

        if foodon_id in values(foodon2umls_mapping)
            continue
        end

        if foodon_id in processed_foodon_ids
            continue
        end

        # Encode the term to be URL-safe
        encoded_foodon_term = HTTP.escape(foodon_term)

        umls_api_key = "3978016a-b02f-4cc4-ae31-cf161882931a"

        umls_url = "https://uts-ws.nlm.nih.gov/rest/search/current?string=$encoded_foodon_term&searchType=normalizedString&apiKey=$umls_api_key"
        #println(umls_url)

        response = HTTP.get(umls_url)
        #println(response)

        if response.status == 200
            results = JSON.parse(String(response.body))
            if !isempty(results["result"]["results"])
                first_result = results["result"]["results"][1]
                umls_cui = first_result["ui"]
                umls_term = first_result["name"]
                println("U $counter / $foodon_terms_count Found UMLS mapping for term (F>U): $foodon_term -> $umls_term [$umls_cui]")
                foodon2umls_mapping[foodon_id] = umls_cui
                print(foodon2umls_mapping_file, "U|F>U|$foodon_id|$foodon_term|$umls_cui|$umls_term\n")
                

            else
                println("N $counter / $foodon_terms_count No UMLS mapping found for term (F>U): $foodon_term")
                print(foodon2umls_mapping_file, "N|F>U|$foodon_id|$foodon_term||\n")
            end
        else
            println("N $counter / $foodon_terms_count Failed to query UMLS for term (F>U): $foodon_term")
            print(foodon2umls_mapping_file, "N|F>U|$foodon_id|$foodon_term||\n")
            push!(non_mapped_terms, foodon_term)
        end
    end


    # close the mapping file
    close(foodon2umls_mapping_file)


end

main()


