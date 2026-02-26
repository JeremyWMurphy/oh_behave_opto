function [] = oh_behave_detect_process()

fs = 2e3;
ttypes = dictionary('goTrial',2,'noGoTrial',3,'pairTrial',4);

pth = 'D:\data\Cue_S2_POm\behavior\gpr26_162\';
runs = {'162_2026-02-22_T17-39-17'};

data = read_teensy_data(pth,runs);

s = get_teensy_behavior(data,fs,ttypes);




