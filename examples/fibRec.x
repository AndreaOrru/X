fibRec(n: Int) -> Int
{
    if (n < 2)
        return n;

    return fibRec(n - 1) + fibRec(n - 2);
}

main() -> Int
{
    return fibRec(10);
}
