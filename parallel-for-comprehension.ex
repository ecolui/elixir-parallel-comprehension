
defmodule Parallel do

    defmacro para({_, context, args}) do

        #For comprehensions, last element in args must be a keywork list that contains :do
        keywordListArg = List.last(args)
        doBlock = Keyword.get(keywordListArg, :do)
        modifiedDoBlock = newProcessWrapper(doBlock)  
        keywordListArg = Keyword.put(keywordListArg, :do, modifiedDoBlock)
        originalInto = case Keyword.fetch(keywordListArg,:into) do
            {:ok,dataStructure} -> dataStructure
            _ -> []
        end

        #The new list comprehension retuns process id's. Store those process ids into a List named :pidCollection
        keywordListArg = Keyword.put(keywordListArg, :into, [])
        args = List.replace_at(args, Enum.count(args)-1, keywordListArg)
        parallelFor = {:for, context, args}
        parallelWrapper = {:=, [],[{:pidCollection, [], Parallel}, parallelFor]} 
        quote do
            myPid = self()
            unquote(parallelWrapper)
            results = for j <- 1..Enum.count(pidCollection), [into: unquote(originalInto), do: receive [do: (result -> result)]]
        end
    end

    defp newProcessWrapper(expr) do
        {:spawn, [context: Elixir, import: Kernel],
            [{:fn, [],
            [{:->, [],
                [[],
                {:send, [context: Elixir, import: Kernel],
                [{:myPid, [], Parallel}, expr]}]}]}]}
    end
end
