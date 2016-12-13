function [max_llrecord, plots1, plots2] = plot_curve(if_test, records, fig, max1, plots1, plots2, color)
    subplot(1,2,1);
    max_llrecord = max1;
    llrecord_mean = zeros(size(records{1}.llrecord(:,1)));
    errrecord_mean = zeros(size(records{1}.errrecord(:,1)));
    llrecord_mean_test = zeros(size(records{1}.llrecord(:,2)));
    errrecord_mean_test = zeros(size(records{1}.errrecord(:,2)));
    trials = length(records);
    
    for trial = 1:trials
        iters = size(records{trial}.llrecord, 1) - 1;
        x_inds = 0:iters;
%         x_inds = records{trial}.eval_gs;
        trial_curve = semilogy(x_inds, -records{trial}.llrecord(:,1), 'Color', color, 'LineWidth', 1.5);
        trial_curve.LineStyle = '-';
        trial_curve.Color(4) = 0.2;
        llrecord_mean = llrecord_mean + (-records{trial}.llrecord(:,1));
        hold on;
        if max(max(-records{trial}.llrecord)) > max_llrecord
            max_llrecord = max(max(-records{trial}.llrecord));
        end
        if if_test
%             trial_curve_test = semilogy(x_inds, -records{trial}.llrecord(:,2));
%             trial_curve_test.LineStyle = '--';
%             trial_curve_test.Color(4) = 0.2;
            hold on;
            llrecord_mean_test = llrecord_mean_test + (-records{trial}.llrecord(:,2));
        end
    end
    llrecord_mean = llrecord_mean / trials;
    plot1 = semilogy(x_inds, llrecord_mean, '-', 'Color', color, 'LineWidth', 2.5); hold on;
    plots1 = [plots1; plot1];
    if if_test
        llrecord_mean_test = llrecord_mean_test / trials;
        semilogy(x_inds, llrecord_mean_test, '--', 'Color', color, 'LineWidth', 2.5); hold on;
    end
    
    subplot(1,2,2);
    for trial = 1:trials
        iters = size(records{trial}.llrecord, 1) - 1;
        x_inds = 0:iters;
%         x_inds = records{trial}.eval_gs;
        trial_curve = plot(x_inds, records{trial}.errrecord(:,1), 'Color', color, 'LineWidth', 1.5);
        trial_curve.LineStyle = '-';
        trial_curve.Color(4) = 0.2;
        errrecord_mean = errrecord_mean + records{trial}.errrecord(:,1);
        hold on;
        if if_test
%             trial_curve_test = plot(x_inds, records{trial}.errrecord(:,2),'b-'); hold on;
%             trial_curve_test.Color(4) = 0.2;
            hold on;
            errrecord_mean_test = errrecord_mean_test + (records{trial}.errrecord(:,2));
        end
    end
    errrecord_mean = errrecord_mean / trials;
    plot2 = plot(x_inds, errrecord_mean, '-', 'Color', color, 'LineWidth', 2.5); hold on;
    plots2 = [plots2; plot2];
    if if_test
        errrecord_mean_test = errrecord_mean_test / trials;
        plot(x_inds, errrecord_mean_test, '--', 'Color', color, 'LineWidth', 2.5);
    end
end