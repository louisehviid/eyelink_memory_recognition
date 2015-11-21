function plotEdfPA(filename)
    res = edfmex(filename)
    plot(res.FSAMPLE.pa(2,1:length(res.FSAMPLE.pa)))
end