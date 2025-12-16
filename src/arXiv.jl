module arXiv

using Dates
using XML
using HTTP

export ArXivEntry, get_daily_updates

const ARXIV_BASE_URL = "http://export.arxiv.org/api/query"
const ATOM_DATETIME_FORMAT = dateformat"yyyy-mm-ddTHH:MM:SSZ"

"""
	ArXivEntry

Parsed representation of a single arXiv record from the Atom feed.
"""
struct ArXivEntry
	id::String
	title::String
	summary::String
	published::DateTime
	updated::DateTime
	authors::Vector{String}
	link::String
	categories::Vector{String}
end

"""
	get_daily_updates(; categories=["cs.LG"], date=Date(now(UTC)), start=0, max_results=200, filter_by_updated=false)

Fetch arXiv entries submitted on the given `date` (UTC) for the provided `categories`.
Results are retrieved in descending submission order via the arXiv API and filtered locally
by the date contained in the Atom feed. By default it inspects the `published` field;
set `filter_by_updated=true` to filter by the `updated` field instead.
"""
function get_daily_updates(; categories::AbstractVector{<:AbstractString}=["cs.LG"], date::Date=Date(now(UTC)), start::Int=0, max_results::Int=200, filter_by_updated::Bool=false)
	@assert max_results > 0 "max_results must be positive"
	@assert start >= 0 "start must be non-negative"

	url = _build_query(categories; start=start, max_results=max_results)
	feed = _fetch_feed(url)
	entries = _parse_entries(feed)
	field = filter_by_updated ? :updated : :published

	return filter(e -> Date(getfield(e, field)) == date, entries)
end

function _build_query(categories; start::Int, max_results::Int)
	category_query = join("cat:" .* categories, "+OR+")
	params = [
		"search_query=$(category_query)",
		"start=$(start)",
		"max_results=$(max_results)",
		"sortBy=submittedDate",
		"sortOrder=descending"
	]
	return string(ARXIV_BASE_URL, "?", join(params, "&"))
end

function _fetch_feed(url::String)
	res = HTTP.get(url)
	res.status == 200 || error("arXiv request failed with status $(res.status)")
	return String(res.body)
end

function _parse_entries(feed::String)
	doc = parse(XML.Node, feed)
	root = _first_element(XML.children(doc))
	root === nothing && return XML.Node[]
	entries = _find_elements(root, "entry")
	return map(_parse_entry, entries)
end

function _parse_entry(node::XML.Node)
	published = _parse_datetime(_element_text(node, "published"))
	updated = _parse_datetime(_element_text(node, "updated"))

	ArXivEntry(
		strip(_element_text(node, "id")),
		_squish(_element_text(node, "title")),
		_squish(_element_text(node, "summary")),
		published,
		updated,
		_parse_authors(node),
		_parse_link(node),
		_parse_categories(node),
	)
end

function _parse_datetime(value::AbstractString)
	isempty(value) && error("Missing datetime field in arXiv entry")
	return DateTime(strip(value), ATOM_DATETIME_FORMAT)
end

function _parse_authors(node::XML.Node)
	authors = _find_elements(node, "author")
	return [strip(_element_text(a, "name")) for a in authors if !isempty(_element_text(a, "name"))]
end

function _parse_categories(node::XML.Node)
	categories = _find_elements(node, "category")
	terms = String[]
	for c in categories
		attrs = XML.attributes(c)
		if attrs !== nothing && haskey(attrs, "term")
			push!(terms, attrs["term"])
		end
	end
	return terms
end

function _parse_link(node::XML.Node)
	links = _find_elements(node, "link")
	alt = _find_first_with_attr(links, "rel", "alternate")
	chosen = alt === nothing ? first(links, nothing) : alt
	chosen === nothing && return ""
	attrs = XML.attributes(chosen)
	attrs === nothing && return ""
	return get(attrs, "href", "")
end

function _find_first_with_attr(nodes::Vector{XML.Node}, key::AbstractString, value::AbstractString)
	for n in nodes
		attrs = XML.attributes(n)
		if attrs !== nothing && get(attrs, key, nothing) == value
			return n
		end
	end
	return nothing
end

function _element_text(node::XML.Node, tagname::AbstractString, default::AbstractString="")
	elements = _find_elements(node, tagname)
	isempty(elements) && return default
	return _text_content(first(elements))
end

function _text_content(node::XML.Node)
	texts = String[]
	for child in XML.children(node)
		if XML.nodetype(child) == XML.Text || XML.nodetype(child) == XML.CData
			push!(texts, XML.value(child))
		end
	end
	return join(texts)
end

function _find_elements(node::XML.Node, name::AbstractString)
	return [child for child in XML.children(node) if XML.nodetype(child) == XML.Element && XML.tag(child) == name]
end

function _first_element(nodes)
	for n in nodes
		XML.nodetype(n) == XML.Element && return n
	end
	return nothing
end

function _squish(text::AbstractString)
	stripped = strip(text)
	return replace(stripped, r"\s+" => " ")
end

end # module arXiv
