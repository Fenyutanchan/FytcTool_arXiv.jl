# Copyright (c) 2025 Fenyutanchan <fenyutanchan@gmail.com>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

export arXivEntry

"""
    arXivEntry

Parsed representation of a single arXiv record from the Atom feed.
"""
struct arXivEntry
    id::String
    title::String
    summary::String
    published::DateTime
    updated::DateTime
    authors::Vector{String}
    link::String
    categories::Vector{String}
end
