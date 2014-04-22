

function main_matlab_check_ALL_false_positive_rate (audio_file)

    % clear;
    % clear all;
    clc;

    % set up dataset path
    dataset_path = 'C:\Users\Mi Zhang\Desktop\VoiceDetection\Datasets\labeledData_selected\';
    label_path = 'C:\Users\Mi Zhang\Desktop\VoiceDetection\Datasets\labeledData_selected_labels\';
    % 1. silence
    % audio_file = 'silent_t1';
    % 2. speech
    % audio_file = 'speech_t3';
    % % 3. classical music
    % audio_file = 'classical_t3';
    % 4. tv 
    % audio_file = 'tv_t5';
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

    % create a second-layer classifier based on the energy ratio and likelihood
%     LF_HF_ratio_threshold_array = [5 10 20 40 60 80 100];
    LF_HF_ratio_threshold_array = [3 5 10 20 40];
    voiced_liklihood_threshold = -2;
    peak_number_threshold = 7;
        
    FPR_array = zeros(size(LF_HF_ratio_threshold_array));

    for j = 1:length(LF_HF_ratio_threshold_array)

    %
    LF_HF_ratio_threshold = LF_HF_ratio_threshold_array(j);
    inference_result_2nd_layer = inference_result;
    for i = 1:length(inference_result_2nd_layer)
        if inference_result(i) == 1
            if LF_HF_ratio(i) <= LF_HF_ratio_threshold || log10(voiced_liklihood(i)) <= voiced_liklihood_threshold || peak_number(i) >= peak_number_threshold
                inference_result_2nd_layer(i) = 0;
            end        
        end    
    end

    % calculate the evaluation metrics
    [TPR, FPR, ACC, Precision, Recall, confusion_matrix] = compute_evaluation_metric(final_label_array, inference_result_2nd_layer);    
    FPR_array(j) = FPR;

    % plot the inference results
    figure;
    subplot(211)
    specgram(raw_audio_data, framesize, framestep);
    hold on
    plot(inference_result*30,'b');
    hold off
    xlabel('Inference Result');
    axis tight
    subplot(212)
    specgram(raw_audio_data, framesize, framestep);
    hold on
    plot(inference_result_2nd_layer*30,'k');
    hold off
    xlabel('Inference Result 2nd Layer');
    axis tight
    % put a single title for all subplots
    ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
    text(0.5, 1, [audio_file, ': LF / HF Ratio: ', num2str(LF_HF_ratio_threshold)], 'HorizontalAlignment','center', 'VerticalAlignment','top');

    %
    saveas(gcf, [audio_file '_500Hz_energy_ratio_threshold_' num2str(LF_HF_ratio_threshold) '_likelihood_' num2str(voiced_liklihood_threshold)], 'jpg');    

    end

    % plot the FPR curve
    figure;
    plot(LF_HF_ratio_threshold_array,FPR_array,'rs-');
    title([audio_file, ': LF / HF Ratio Feature Setting: 500Hz, Likelihood: ' num2str(voiced_liklihood_threshold) ' (log10)'], 'FontSize', 18);
    xlabel('LF / HF Ratio');
    ylabel('False Positive Rate (%)');

    % save the TPR-FPR curve
    saveas(gcf, [audio_file '_500Hz_energy_ratio_likelihood_FPR'], 'jpg');    


    



