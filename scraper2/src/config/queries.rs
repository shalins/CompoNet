pub const ATTRIBUTE_BUCKET_QUERY: &str = r"
query FilterModalSearch($attribute_names: [String!]!, $currency: String!, $filters: Map, $in_stock_only: Boolean, $q: String) {
    search(currency: $currency, filters: $filters, in_stock_only: $in_stock_only, q: $q) {
        hits
        spec_aggs(attribute_names: $attribute_names, size: 100) {
            buckets {
                count
                display_value
                float_value
            }
        }
    }
}
";

pub const PART_SEARCH_QUERY: &str = r"
query PricesViewSearch($country: String!, $currency: String!, $filters: Map, $in_stock_only: Boolean, $limit: Int!, $q: String, $sort: String, $sort_dir: SortDirection, $start: Int) {
  search(country: $country, currency: $currency, filters: $filters, in_stock_only: $in_stock_only, limit: $limit, q: $q, sort: $sort, sort_dir: $sort_dir, start: $start) {
    applied_category {
      ancestors {
        id
        name
        path
      }
      id
      name
      path
    }
    applied_filters {
      display_values
      name
      shortname
      values
    }
    results {
      _cache_id
      description
      part {
        _cache_id
        best_datasheet {
          url
        }
        best_image {
          url
        }
        category {
          id
        }
        counts
        descriptions {
          text
        }
        id
        manufacturer {
          id
          is_verified
          name
        }
        manufacturer_url
        median_price_1000 {
          _cache_id
          converted_currency
          converted_price
        }
        mpn
        specs {
          attribute {
            id
            name
            shortname
          }
          display_value
        }
      }
    }
    hits
  }
}
";
