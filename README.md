# `arXiv.jl`: Access arXiv Preprints

It is a tool package for accessing and downloading preprints from the arXiv prerint server (https://arxiv.org/).

## Usage

```julia
using arXiv
using Dates

# Fetch today's cs.LG submissions (UTC) sorted by submission time
entries = get_daily_updates(categories=["cs.LG"], date=Date(now(UTC)), max_results=200)

for e in entries
	println("[" * string(Date(e.published)) * "] " * e.title)
	println("Authors: " * join(e.authors, ", "))
	println("Link: " * e.link)
	println()
end
```

Pass multiple categories to query combined feeds and set `filter_by_updated=true` if
you prefer to filter by the `updated` timestamp instead of `published`.
