
# This script fetches all the terms from the FOODON ontology using the OLS API and writes them to a file.
# It also fetches all the food terms from the UMLS directory and writes them to a file.

# the output files are written in the src_terms directory



using HTTP
using JSON
using FilePathsBase

function fetch_all_terms(base_url::String, all_terms::Vector{Dict{String, Any}})
    println("Fetching all terms from the OLS API for FOODON...")

    # Define the endpoint for retrieving all terms
    endpoint = "$base_url/terms"
    println(endpoint)

    # Pagination variables
    page = 0
    size = 1000

    while true
        # Make the request to the OLS API with pagination
        response = HTTP.get(endpoint, query = Dict("size" => string(size), "page" => string(page)))

        # Check if the request was successful
        if response.status == 200
            # Parse the JSON response
            data = JSON.parse(String(response.body))

            # Check if the "terms" key exists
            if haskey(data, "_embedded") && haskey(data["_embedded"], "terms")
                # Extract the list of terms
                terms = data["_embedded"]["terms"]
                # Add the terms to the list
                for term in terms
                    # Check if the term is not obsolete and is in the FoodOn ontology
                    if (!haskey(term, "is_obsolete") || term["is_obsolete"] == false) && startswith(term["short_form"], "FOODON")
                        push!(all_terms, Dict(term))
                    end
                end
                # Check if there are more pages
                if data["page"]["totalPages"] <= page + 1
                    break
                end
                # Increment the page number
                page += 1
            else
                println("No terms found.")
                break
            end
        else
            println("Failed to retrieve terms: $(response.status)")
            break
        end
    end
end

function ols_lookup_all_foodon_terms(base_url::String, output_file::String)
    # Initialize an empty list to store all terms
    all_terms = Vector{Dict{String, Any}}()

    # Fetch all terms
    fetch_all_terms(base_url, all_terms)

    # Write the list of all terms to the output file in the form: ID | Term
    open(output_file, "w") do file
        for term in all_terms
            println(file, "$(term["short_form"])|$(term["label"])")
        end
    end
end


function create_directory_if_not_exists(dir::String)
    if !isdir(dir)
        mkpath(dir)
        println("Directory created: $dir")
    else
        println("Directory already exists: $dir")
    end
end

function fetch_sources_from_mrconso(umls_dir::String, cuis::Set{String}, output_file::String)
    # Define the path to the MRCONSO.RRF file
    mrconso_file = joinpath(umls_dir, "MRCONSO.RRF")

    # Check if the MRCONSO.RRF file exists
    if !isfile(mrconso_file)
        println("MRCONSO.RRF file not found in the UMLS directory.")
        return
    end

    # Initialize a dictionary to store sources with CUI as key
    cui_sources = Dict{String, Set{String}}()

    # Open the MRCONSO.RRF file and read line by line
    open(mrconso_file, "r") do file
        for line in eachline(file)
            fields = split(line, "|")
            cui = fields[1]
            sab = fields[12]

            # Check if the CUI is in the given set of CUIs
            if cui in cuis
                if !haskey(cui_sources, cui)
                    cui_sources[cui] = Set{String}()
                end
                push!(cui_sources[cui], sab)
            end
        end
    end

    # Write the list of sources to the output file in the form: CUI | SAB
    open(output_file, "w") do file
        for (cui, sources) in cui_sources
            for source in sources
                println(file, "$cui|$source")
            end
        end
    end
end


function umls_food_term_lookup(umls_dir::String, output_file::String, sab_output_file::String)
    println("Fetching food terms from the UMLS directory...")

    # Define the path to the MRSTY.RRF file
    mrsty_file = joinpath(umls_dir, "MRSTY.RRF")

    # Define the path to the MRCONSO.RRF file
    mrconso_file = joinpath(umls_dir, "MRCONSO.RRF")

    # Check if the MRSTY.RRF file exists
    if !isfile(mrsty_file)
        println("MRSTY.RRF file not found in the UMLS directory.")
        return
    end

    # Check if the MRCONSO.RRF file exists
    if !isfile(mrconso_file)
        println("MRCONSO.RRF file not found in the UMLS directory.")
        return
    end

    # Initialize a set to store CUIs with the semantic type T168 (food)
    food_cuis = Set{String}()


    # Open the MRSTY.RRF file and read line by line
    open(mrsty_file, "r") do file
        for line in eachline(file)
            fields = split(line, "|")
            # Check if the semantic type is T168 (food)
            if fields[2] == "T168"
                push!(food_cuis, fields[1])
            end
        end
    end

    # Fetch sources for the food CUIs
    fetch_sources_from_mrconso(umls_dir, food_cuis, sab_output_file)

    # Initialize a dictionary to store food terms with CUI as key
    food_terms = Dict{String, String}()

    # Open the MRCONSO.RRF file and read line by line
    open(mrconso_file, "r") do file
        for line in eachline(file)
            fields = split(line, "|")
            cui = fields[1]
            language = fields[2]
            is_preferred = fields[7]
            term = fields[15]

            # Check if the CUI is in the food_cuis set and the language is English
            if cui in food_cuis && language == "ENG" && is_preferred == "Y"
                # Add the term to the dictionary if not already present
                if !haskey(food_terms, cui)
                    food_terms[cui] = term
                end
            end
        end
    end

    # Write the list of food terms to the output file in the form: CUI | Term
    open(output_file, "w") do file
        for (cui, term) in food_terms
            println(file, "$cui|$term")
        end
    end
end

function retrieve_foodon_terms()
    # Define the foodon terms file path
    foodon_terms_file = joinpath(output_dir, "foodon_terms.psv")

    # Check if the foodon terms file already exists
    if !isfile(foodon_terms_file)
        println("Output file does not exist. Fetching terms...")
        # Define the base URL for the OLS API
        base_url = "https://www.ebi.ac.uk/ols4/api/ontologies/foodon"
        ols_lookup_all_foodon_terms(base_url, foodon_terms_file)
    else
        println("FOODON Src terms file already exists. Skipping fetch.")
    end
end



# Define the directory to store the output files
output_dir = "src_terms"

# Create the directory if it does not exist
create_directory_if_not_exists(output_dir)

#retrieve_foodon_terms()

# Define the UMLS source file directory
umls_source_dir = "../_data/umls/2024AB/META"

umls_food_items_file = joinpath(output_dir, "umls_food_items.psv")
umls_food_sources_file = joinpath(output_dir, "umls_food_sources.psv")

# Define the UMLS food items file path
if !isfile(umls_food_items_file)
    println("UMLS food items file does not exist. Fetching items...")
     
    umls_food_term_lookup(umls_source_dir, umls_food_items_file, umls_food_sources_file)

else
    println("UMLS food items file already exists. Skipping fetch.")
end






