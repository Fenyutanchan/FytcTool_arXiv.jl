# Copyright (c) 2025 Fenyutanchan <fenyutanchan@gmail.com>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

export get_daily_updates

"""
	get_daily_updates(;
		categories::AbstractVector{<:AbstractString}=["hep-ph"],
		max_results_per_call::Int=50,
		include_updated::Bool=true
	)::Vector{arXivEntry}

Fetch arXiv preprints daily updates for the specified categories.
Results are retrieved in descending submission order via the arXiv API and filtered locally by the date contained in the Atom feed.
Set `include_updated=false` to filter by the `updated` field instead.
"""
function get_daily_updates(;
	categories::AbstractVector{<:AbstractString}=["hep-ph"],
	max_results_per_call::Int=50,
	include_updated::Bool=true
)
	@assert max_results_per_call > 0 "max_results_per_call must be positive"
	# @assert start >= 0 "start must be non-negative"

	final_entries = arXivEntry[]

	rss_url = string(ARXIV_RSS_URL, join(categories, "+"))
	rss_body = __fetch_feed(rss_url)
	doc = parse(XML.Node, rss_body)
	links = filter!(contains("abs"), map(__text_content, __find_elements_recursive(doc, "link")))
	arXiv_IDs = String[]
	for link ∈ links
		m = match(ARXIV_ID_REGEX, link)
		if isnothing(m)
			@warn "Failed to extract arXiv ID from link: $link, skipping."
			continue
		end
		push!(arXiv_IDs, m.match)
	end

	start = 1
	found_arXiv_IDs = String[]
	while start ≤ length(arXiv_IDs)
		other_query_params = Dict(
			"id_list" => join(arXiv_IDs[start:min(start+max_results_per_call-1,end)], ",")
		)
		url = __build_query(0, max_results_per_call;
			other_query_params = other_query_params
		)
		feed = __fetch_feed(url)
		entries = __parse_entries(feed)
		union!(final_entries, entries)
		union!(found_arXiv_IDs, [e.id for e ∈ entries])

		start += max_results_per_call
	end

	for (ii, found_arXiv_ID) ∈ enumerate(found_arXiv_IDs)
		v_index = findfirst('v', found_arXiv_ID)
		isnothing(v_index) && continue
		found_arXiv_IDs[ii] = found_arXiv_ID[1:v_index-1]
	end
	if (!isempty ∘ symdiff)(arXiv_IDs, found_arXiv_IDs)
		not_found_IDs = setdiff(arXiv_IDs, found_arXiv_IDs)
		extra_found_IDs = setdiff(found_arXiv_IDs, arXiv_IDs)
		isempty(not_found_IDs) || @warn "Some arXiv IDs were not found: $(join(not_found_IDs, ", "))"
		isempty(extra_found_IDs) || @warn "Some unexpected arXiv IDs were found: $(join(extra_found_IDs, ", "))"
		error("Discrepancy in fetched arXiv IDs.")
	end

	include_updated || filter!(e.published == e.updated, final_entries)

	return final_entries
end
