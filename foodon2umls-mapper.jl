using FilePathsBase

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
foodon2umls_mapping_file = open(foodon2umls_mapping_file_name, "w")

# foodon2umls_no_mapping_file_name = joinpath(map_dir_path, "foodon2umls_no_mapping.psv")
# foodon2umls_no_mapping_file = open(foodon2umls_no_mapping_file_name, "w")


# Define the dictionary to store the mappings
foodon2umls_mapping = Dict{String, String}()

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

# create set to keep track of non-mapped terms
non_mapped_terms = Set{String}()

# Iterate over the UMLS terms and find direct mappings (UMLS term == FoodOn term)
for (umls_term, umls_cui) in umls_terms

    # println("Processing UMLS term: $umls_term")

    # direct mappings
    if haskey(foodon_terms, umls_term)
        println("D Found direct mapping for term (U>F): $umls_term")
        foodon2umls_mapping[foodon_terms[umls_term]] = umls_cui
        print(foodon2umls_mapping_file, "D|$(foodon_terms[umls_term])|$umls_term|$umls_cui|$umls_term\n")
        # exit()
    else
        #println("No direct mapping found for term (U>F): $umls_term")

        # Send the term to OLS to search the FoodOn ontology
        using HTTP
        using JSON

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
                println("O Found OLS mapping for term (U>F): $umls_term -> $foodon_term [$foodon_id]")
                foodon2umls_mapping[foodon_id] = umls_cui
                print(foodon2umls_mapping_file, "O|$foodon_id|$foodon_term|$umls_cui|$umls_term\n")
                #exit()
            # else
            #     println("X No OLS mapping found for term (U>F): $umls_term")
            end
        else
            println("N Failed to query OLS for term (U>F): $umls_term")

            print(foodon2umls_mapping_file, "N|||$umls_cui|$umls_term\n")
            push!(non_mapped_terms, umls_term)
            exit()
        end


    end

end

exit()



