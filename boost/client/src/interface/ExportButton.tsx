import React from "react";
import { Point } from "../utils/types";

interface ExportButtonProps {
    points: Point[];
}

export default function ExportButton({ points }: ExportButtonProps) {
    const exportCSV = () => {
        // Create the header
        const headers = "MPN,Manufacturer,URL,X-Axis,Y-Axis,X-Units,Y-Units\n"

        // Add the rows
        const rows = points.map(point => 
            `${point.mpn},${point.manufacturer},${point.link},${point.xAxis},${point.yAxis},${point.xUnits},${point.yUnits}`
        ).join('\n');

        const csvContent = headers + rows;
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      
        // Create a link and trigger the download
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', 'selected_components.csv');
        document.body.appendChild(link); // Required for Firefox
        link.click();
        document.body.removeChild(link); // Clean up
    };
  
    return (
        <div>
            {points.length > 0 && (
                    <button onClick={exportCSV}>
                    Export CSV
                    </button>
            )}
        </div>
    );
}
  