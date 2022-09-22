import { attributeNames, attributeShortnames } from "./octopart";

export const generateQuery = (category: string, attributes: string[]) => {
  // We want to geenrate a SQL query that selects attributes that we wanted
  // from all the different categories that we want.

  // Convert all the attrbiute names to shortnames.
  const queryAttributes = attributes.map((name) => attributeShortnames[name]);

  // Then generate the query.
  let query = "SELECT ";

  // Add the attributes to the query.
  queryAttributes.forEach((attribute, idx) => {
    query += `part_specs_${attribute}_display_value`;
    if (idx !== queryAttributes.length - 1) {
      query += ", ";
    }
  });

  query += ` FROM public.all WHERE part_category_id='${category}' AND `;

  // Go through the attributes and add the conditions.
  queryAttributes.forEach((attribute, idx) => {
    query += `part_specs_${attribute}_display_value IS NOT NULL AND `;
    query += `part_specs_${attribute}_display_value != 'nan' `;
    if (idx !== queryAttributes.length - 1) {
      query += " AND ";
    }
  });

  query += ";";

  console.log(query);

  return query;
};
