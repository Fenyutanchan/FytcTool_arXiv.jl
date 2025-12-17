module arXiv

using Dates
using HTTP
using TimeZones
using XML

export get_daily_updates

const ARXIV_BASE_URL = "http://export.arxiv.org/api/query"
const ATOM_DATETIME_FORMAT = dateformat"yyyy-mm-ddTHH:MM:SS\UTCz"

include("arXivEntry.jl")
include("utils.jl")

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

	url = __build_query(categories; start=start, max_results=max_results)
	feed = __fetch_feed(url)
	entries = __parse_entries(feed)
	field = filter_by_updated ? :updated : :published

	return filter(e -> Date(getfield(e, field)) == date, entries)
end

end # module arXiv
