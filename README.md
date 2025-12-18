# `FytcTool_arXiv.jl`: Access arXiv Preprints

It is a tool package for accessing and downloading preprints from the arXiv prerint server (https://arxiv.org/). Now it mainly provides a function to get the latest daily submissions from specified arXiv categories, which returns structured data records.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/Fenyutanchan/FytcTool_arXiv.jl.git")
```

## Quick start

```julia
using FytcTool_arXiv

# Pull today's `hep-ph` and `hep-th` submissions, including updates.
entries = get_daily_updates(categories=["hep-ph", "hep-th"])

for e ∈ entries
    println("[$(e.id)] ", e.title)
    println("Authors: ", join(e.authors, ", "))
    println("Link: ", e.link)
    println("Abstract: ", e.summary)
    println()
end
```

## API

- `get_daily_updates(; categories=["hep-ph"], max_results_per_call=50, include_updated=true)`
    - Downloads the category RSS, extracts arXiv IDs, then hydrates them via the API.
    - Results are sorted by submission time; set `include_updated=false` to drop entries where `updated` differs from `published`.

### Returned type

Each entry is an `arXivEntry` with fields:

- `id` (e.g., "2501.01234v1")
- `title`
- `summary`
- `published` and `updated` (`DateTime`, UTC)
- `authors` (vector of strings)
- `link` (abstract page)
- `categories` (vector of category codes)

## Notes

- The function fetches in batches of `max_results_per_call`; increase if you expect more articles in one request.
- Networking uses HTTP and XML parsing; you need internet access to run it.
