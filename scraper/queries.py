ATTRIBUTE_BUCKET_QUERY = """
query FilterModalSearch($attribute_names: [String!]!, $currency: String!, \
  $filters: Map, $in_stock_only: Boolean, $q: String) {
    search(currency: $currency, filters: $filters, in_stock_only: $in_stock_only, q: $q) {
        hits
        spec_aggs(attribute_names: $attribute_names, size: 1000000000) {
            buckets {
                count
                display_value
                float_value
                __typename
            }
        }
        __typename
    }
}
"""

PART_SEARCH_QUERY = """
query PricesViewSearch($country: String!, $currency: String!, $filters: Map, $in_stock_only: \
  Boolean, $limit: Int!, $q: String, $sort: String, $sort_dir: SortDirection, $start: Int) {
  search(country: $country, currency: $currency, filters: $filters, in_stock_only: $in_stock_only, \
    limit: $limit, q: $q, sort: $sort, sort_dir: $sort_dir, start: $start) {
    applied_category {
      ancestors {
        id
        name
        path
        __typename
      }
      id
      name
      path
      __typename
    }
    applied_filters {
      display_values
      name
      shortname
      values
      __typename
    }
    results {
      _cache_id
      description
      part {
        _cache_id
        best_datasheet {
          url
          __typename
        }
        best_image {
          url
          __typename
        }
        category {
          id
          __typename
        }
        counts
        descriptions {
          text
          __typename
        }
        id
        manufacturer {
          id
          is_verified
          name
          __typename
        }
        manufacturer_url
        median_price_1000 {
          _cache_id
          converted_currency
          converted_price
          __typename
        }
        mpn
        specs {
          attribute {
            id
            name
            shortname
            __typename
          }
          display_value
          __typename
        }
        __typename
      }
      __typename
    }
    hits
    __typename
  }
}
"""
