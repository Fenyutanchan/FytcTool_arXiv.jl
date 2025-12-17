# Copyright (c) 2025 Fenyutanchan <fenyutanchan@gmail.com>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

function __build_query(categories; start::Int, max_results::Int)
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

function __fetch_feed(url::String)
    res = HTTP.get(url)
    res.status == 200 || error("arXiv request failed with status $(res.status)")
    return String(res.body)
end

function __parse_entries(feed::String)
    doc = parse(XML.Node, feed)
    root = __first_element(XML.children(doc))
    root === nothing && return XML.Node[]
    entries = __find_elements(root, "entry")
    return map(__parse_entry, entries)
end

function __parse_entry(node::XML.Node)
    published = __parse_datetime(__element_text(node, "published"))
    updated = __parse_datetime(__element_text(node, "updated"))

    arXivEntry(
        strip(__element_text(node, "id")),
        __squish(__element_text(node, "title")),
        __squish(__element_text(node, "summary")),
        published,
        updated,
        __parse_authors(node),
        __parse_link(node),
        __parse_categories(node),
    )
end

function __parse_datetime(value::AbstractString)
    isempty(value) && error("Missing datetime field in arXiv entry")
    return DateTime(strip(value), ATOM_DATETIME_FORMAT)
end

function __parse_authors(node::XML.Node)
    authors = __find_elements(node, "author")
    return [strip(__element_text(a, "name")) for a in authors if !isempty(__element_text(a, "name"))]
end

function __parse_categories(node::XML.Node)
    categories = __find_elements(node, "category")
    terms = String[]
    for c in categories
        attrs = XML.attributes(c)
        if attrs !== nothing && haskey(attrs, "term")
            push!(terms, attrs["term"])
        end
    end
    return terms
end

function __parse_link(node::XML.Node)
    links = __find_elements(node, "link")
    alt = __find_first_with_attr(links, "rel", "alternate")
    chosen = alt === nothing ? first(links, nothing) : alt
    chosen === nothing && return ""
    attrs = XML.attributes(chosen)
    attrs === nothing && return ""
    return get(attrs, "href", "")
end

function __find_first_with_attr(nodes::Vector{XML.Node}, key::AbstractString, value::AbstractString)
    for n in nodes
        attrs = XML.attributes(n)
        if attrs !== nothing && get(attrs, key, nothing) == value
            return n
        end
    end
    return nothing
end

function __element_text(node::XML.Node, tagname::AbstractString, default::AbstractString="")
    elements = __find_elements(node, tagname)
    isempty(elements) && return default
    return __text_content(first(elements))
end

function __text_content(node::XML.Node)
    texts = String[]
    for child in XML.children(node)
        if XML.nodetype(child) == XML.Text || XML.nodetype(child) == XML.CData
            push!(texts, XML.value(child))
        end
    end
    return join(texts)
end

function __find_elements(node::XML.Node, name::AbstractString)
    return [child for child in XML.children(node) if XML.nodetype(child) == XML.Element && XML.tag(child) == name]
end

function __first_element(nodes)
    for n in nodes
        XML.nodetype(n) == XML.Element && return n
    end
    return nothing
end

function __squish(text::AbstractString)
    stripped = strip(text)
    return replace(stripped, r"\s+" => " ")
end
