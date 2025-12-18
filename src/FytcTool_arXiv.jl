# Copyright (c) 2025 Fenyutanchan <fenyutanchan@gmail.com>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module FytcTool_arXiv

using Dates
using HTTP
using XML

const ARXIV_QUERY_URL = "http://export.arxiv.org/api/query"
const ARXIV_RSS_URL = "http://export.arxiv.org/rss/"
const ARXIV_ID_REGEX = r"(?:\d{4}\.\d{4,5}|[a-z-]+(?:\.[A-Z]{2})?/\d{7})(?:v\d+)?"
const ATOM_DATETIME_FORMAT = dateformat"yyyy-mm-ddTHH:MM:SSZ"

include("arXivEntry.jl")

include("get_daily_updates.jl")
include("utils.jl")

end # module FytcTool_arXiv
