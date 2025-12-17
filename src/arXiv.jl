# Copyright (c) 2025 Fenyutanchan <fenyutanchan@gmail.com>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module arXiv

using Dates
using HTTP
using TimeZones
using XML

const ARXIV_BASE_URL = "http://export.arxiv.org/api/query"
const ATOM_DATETIME_FORMAT = dateformat"yyyy-mm-ddTHH:MM:SS\UTCz"

include("arXivEntry.jl")

include("get_daily_updates.jl")
include("utils.jl")

end # module arXiv
