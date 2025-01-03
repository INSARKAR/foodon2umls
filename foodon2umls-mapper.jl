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

# Define the output file path for the mapping
foodon2umls_mapping_file = joinpath(map_dir_path, "foodon2umls_mapping-direct.psv")
umls2foodon_mapping_file = joinpath(map_dir_path, "umls2foodon_mapping-direct.psv")

# Define the dictionary to store the mappings
foodon2umls_mapping = Dict{String, String}()
umls2foodon_mapping = Dict{String, String}()

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

        foodon_terms[foodon_id] = term
    end
end

# Load the umls terms into a dictionary
umls_terms = Dict{String, String}()
open(umls_food_items_file, "r") do file
    for line in eachline(file)
        cui, term = split(line, '|')
        term = lowercase(term)
        umls_terms[cui] = term
    end
end


# Iterate over the foodon terms and find direct mappings (FoodOn term == UMLS term)
for (foodon_id, foodon_term) in foodon_terms

    println("Processing FOODON term: $foodon_term")

    for (umls_cui, umls_term) in umls_terms
        if foodon_term == umls_term
            println("Found direct mapping for term (F>U): $foodon_term")
            foodon2umls_mapping[foodon_id] = umls_cui
            umls2foodon_mapping[umls_cui] = foodon_id
        end
    end
end

# Iterate over the UMLS terms and find direct mappings (UMLS term == FoodOn term)
for (umls_cui, umls_term) in umls_terms

    println("Processing UMLS term: $umls_term")

    for (foodon_id, foodon_term) in foodon_terms

        if haskey(umls2foodon_mapping, umls_cui)
            continue
        end

        if umls_term == foodon_term
            println("Found direct mapping for term (U>F): $umls_term")
            foodon2umls_mapping[foodon_id] = umls_cui
            umls2foodon_mapping[umls_cui] = foodon_id
            exit()
        end
    end
end