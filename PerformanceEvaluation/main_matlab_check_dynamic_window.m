

function voiced_window_feature_array = main_matlab_check_dynamic_window (audio_file)

    % clear;
    % clear all;
    clc;
       
    % set up dataset path
    dataset_path = 'C:\Users\Mi Zhang\Desktop\VoiceDetection\Datasets\labeledData_selected\';
    label_path = 'C:\Users\Mi Zhang\Desktop\VoiceDetection\Datasets\labeledData_selected_labels\';
    % 1. silence
    % audio_file = 'silent_t1';
    % 2. speech
    % audio_file = 'speech_t4';
    % 3. classical music
    % audio_file = 'classical_t4';
    % 4. tv 
    % audio_file = 'tv_t6';
    % 5. pop music
    % audio_file = 'pop_t6';
    % 6. ambient sound
    % audio_file = 'ambient_t6';
    % 7. radio
    % audio_file = 'radio_t1';
    % 8. body sound
    % audio_file = 'bodysound_t7';

    % load raw audio data
    file_name = strcat(dataset_path, audio_file, '.wav');
    raw_audio_data = wavread(file_name);

    % set up parameters
    sampling_rate = 8192;
    framesize = 256;
    framestep = 128;
    num_of_framestep_for_RSE = 300; % number of framesteps for calculating Relative Spectral Entropy (RSE)
    noise_level = 0.02; % white noise level: 0.01 represents 1%.

    % get inference results and feature values
    results = infer(raw_audio_data, sampling_rate, framesize, framestep, noise_level, num_of_framestep_for_RSE);
    inference_result = results(:, 1) - 1; % 0 - unvoiced; 1 - voiced
    LF_HF_ratio = results(:, 8);
    nonvoiced_liklihood = results(:, 9);
    voiced_liklihood = results(:, 10);
    peak_number = results(:, 3);

    % load true labels
    label_name = strcat(label_path, audio_file, '_final_label_array.txt');
    final_label_array = csvread(label_name);
    % Fix the BUG: 
    % The number of framesteps of final_label_array is equal to the number of
    % framesteps of inference_result.
    % So I just remove the last framestep of final_label_array
    final_label_array = final_label_array(1:length(inference_result),:);

    % locate voiced windows 
    voiced_window_array = [];
    voiced_window_length_limit = 64; % 64 framesteps is equal to 1 second
    start_index = 0;
    for i = 1:length(inference_result)    
        if inference_result(i) == 1
            if start_index == 0 % if I am the first 1.
                start_index = i;
            else
                if i == length(inference_result) % if I am the last frame in this trial.
                    end_index = i;
                    voiced_window_array = [voiced_window_array; start_index end_index];
                    start_index = 0;     
                    end_index = 0;
                    break;
                end
                
                if i - start_index + 1 == voiced_window_length_limit % reach the voiced window length limit.
                    end_index = i;
                    voiced_window_array = [voiced_window_array; start_index end_index];
                    start_index = 0;     
                    end_index = 0;
                end                
            end
        end
        
        if inference_result(i) == 0
            if start_index ~= 0
                end_index = i-1;
                voiced_window_array = [voiced_window_array; start_index end_index];
                start_index = 0;     
                end_index = 0;
            end            
        end
    end
    
    % calculate LF/HF energy ratio statistics (mean, std) for each voiced window 
    voiced_window_feature_array = zeros(size(voiced_window_array, 1), 2);
    for i = 1:size(voiced_window_array, 1)
        voiced_window_feature_array(i, 1) = log10(mean(LF_HF_ratio(voiced_window_array(i,1):voiced_window_array(i,2))));
        voiced_window_feature_array(i, 2) = log10(std(LF_HF_ratio(voiced_window_array(i,1):voiced_window_array(i,2)))+ 1e-5);
    end    
    
    
%     % plot the histograms
%     figure;
%     subplot(2,1,1)
%     hist(voiced_window_feature_array(:,1), 10);
%     xlabel('Mean Values of LF / HF Ratio');
%     axis tight
%     subplot(2,1,2)
%     hist(voiced_window_feature_array(:,2), 10);
%     xlabel('STD Values of LF / HF Ratio');
%     axis tight
%     % put a single title for all subplots
%     ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
%     text(0.5, 1, [audio_file, ': LF / HF Ratio: 500Hz'], 'HorizontalAlignment','center', 'VerticalAlignment','top');
% 
%     % save the plot
%     saveas(gcf, [audio_file '_500Hz_energy_ratio'], 'jpg');   
    
    fprintf('I am done!\n');

    
    
    

    




