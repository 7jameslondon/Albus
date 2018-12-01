[loadName, loadPath, ~] = uigetfile({'*.mat'}, 'Select the session to load'); 
if loadName == 0 % if user presses cancel
    flag = true;
    return;
end
load([loadPath loadName]);  

session.tra_groups
traces = session.tra_traces;
traces.Groups