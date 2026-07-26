import marimo

__generated_with = "0.23.15"
app = marimo.App(width="full")


@app.cell
def _():
    import marimo as mo
    import util
    import polars as pl

    return pl, util


@app.cell
def _(util):
    cat = util.get_catalog("platform.smith-data.de")
    cat.create_namespace_if_not_exists("01_bronze")
    cat.create_namespace_if_not_exists("02_silver")
    cat.create_namespace_if_not_exists("03_gold")
    return (cat,)


@app.cell
def _(pl):
    data = [
        {
            "a":420,
            "b":3,
        },
        {
            "a":7,
            "b":8,
        }
    ]
    df = pl.DataFrame(data)
    return (df,)


@app.cell
def _(cat, df):
    tbl = cat.create_table_if_not_exists("01_bronze.test3", schema=df.to_arrow().schema)
    df.write_iceberg(tbl, mode="overwrite")
    return


@app.cell
def _(cat, pl):
    lf = pl.scan_iceberg(
        source="01_bronze.test3",
        catalog=cat,
        reader_override="pyiceberg",
    )
    lf.collect()
    return


if __name__ == "__main__":
    app.run()
