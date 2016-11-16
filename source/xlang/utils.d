module xlang.utils;


/**
 * Generate constructors that simply call the parent class constructors.
 *
 * Based on https://github.com/CyberShadow/ae/blob/302103adced5846d25316bcf14d246e828195232/utils/meta/package.d#L374
 */
mixin template InheritConstructors()
{
    mixin(() {
        import std.conv : text;
        import std.string : join;
        import std.traits : ParameterTypeTuple, fullyQualifiedName;

        alias T = typeof(super);

        string s;
        static if (__traits(hasMember, T, "__ctor"))
            foreach (ctor; __traits(getOverloads, T, "__ctor"))
            {
                string[] declarationList, usageList;
                foreach (i, param; ParameterTypeTuple!(typeof(&ctor)))
                {
                    auto varName = "v" ~ text(i);
                    declarationList ~= fullyQualifiedName!param ~ " " ~ varName;
                    usageList ~= varName;
                }
                s ~= "this(" ~ declarationList.join(", ") ~ ") { super(" ~ usageList.join(", ") ~ "); }\n";
            }
        return s;
    } ());
}
