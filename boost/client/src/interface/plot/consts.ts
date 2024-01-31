
export abstract class PlotConstants {
    static readonly fontFamily = "Times New Roman";
    static readonly fontSize = 14;
    static readonly fontColor = "#000000";
}

export abstract class LegendConstants {
    static readonly location: { x: number; y: number } = { x: 0.7, y: 0.05 };
    static readonly borderColor = "#000000";
    static readonly borderWidth = 1.25;
    static readonly markerSize = 2;
}

export abstract class MarkerConstants {
    static readonly traceColors = [
        "#669900",
        "#99cc33",
        "#006699",
        "#3399cc",
        "#990066",
        "#cc3399",
        "#ff6600",
        "#ff9900",
        "#ffcc00",
    ];
    static readonly defaultTraceColor = "#000000";

    static readonly normalSize = 5.5;
    static readonly normalSymbol = "circle";

    static readonly selectColor = "black";
    static readonly selectSize = 10;
    static readonly selectSymbol = "x";

    static readonly borderSize = 0;
    static readonly opacity = 1.0;
}