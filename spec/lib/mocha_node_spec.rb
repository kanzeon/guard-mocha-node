require 'spec_helper'

describe Guard::MochaNode do
  let(:state)  { Guard::MochaNode::SpecState.new }
  let(:guard)  { Guard::MochaNode.new }

  before do
    Guard::MochaNode::SpecState.stub(:new => state)
    Guard::Notifier.stub(:notify)
    state.stub(:update => true)
  end

  describe "#initialize" do
    context "when no options are given" do
      it "sets a default path to mocha-node bin" do
        guard.options[:mocha_bin].should eql "mocha"
      end

      it "sets :notify option to true" do
        guard.options[:notify].should eql true
      end

      it "sets :all_after_pass option to true" do
        guard.options[:all_after_pass].should be_true
      end

      it "sets :all_on_start option to true" do
        guard.options[:all_on_start].should be_true
      end

      it "sets :keep_failed option to true" do
        guard.options[:keep_failed].should be_true
      end

      it "sets :coffescript option to true" do
        guard.options[:coffeescript].should be_true
      end

      it "sets :livescript option to true" do
        guard.options[:livescript].should be_false
      end

      it "sets :verbose option to true" do
        guard.options[:verbose].should be_true
      end

      it "sets :reporter option to 'spec'" do
        guard.options[:reporter].should eql "spec"
      end

      it "sets :color option to true" do
        guard.options[:color].should eql true
      end

      it "sets :recursive option to true" do
        guard.options[:recursive].should eql true
      end

      it "sets :paths_for_all_specs  option to ['spec']" do
        guard.options[:paths_for_all_specs].should eql ['spec']
      end

      it "is passing" do
        guard.should be_passing
      end

      it "has no failing paths" do
        guard.failing_paths.should be_empty
      end
    end

    context "when options are given" do
      let(:a_path) { "/foo/bar/mocha-node" }
      let(:guard)  { Guard::MochaNode.new([], {
                                              :mocha_bin        => a_path,
                                              :all_on_start     => false,
                                              :all_after_pass   => false,
                                              :keep_failed      => false,
                                              :notify           => false,
					      :coffeescript     => false,
					      :livescript       => true,
					      :reporter         => 'spec',
					      :color            => false,
					      :recursive        => false,
					      :paths_for_all_specs => %w(test)
                                            }) }

      it "sets the path to mocha bin" do
        guard.options[:mocha_bin].should eql a_path
      end

      it "sets the :notify option" do
        guard.options[:notify].should be_false
      end

      it "sets the :all_after_pass option" do
        guard.options[:all_after_pass].should be_false
      end

      it "sets the :all_on_start option" do
        guard.options[:all_on_start].should be_false
      end

      it "sets the :keep_failed option" do
        guard.options[:keep_failed].should be_false
      end

      it "sets the :coffeescript option" do
        guard.options[:coffeescript].should be_false
      end

      it "sets the :livescript option" do
        guard.options[:livescript].should be_true
      end

      it "sets the :reporter option" do
        guard.options[:reporter].should eql 'spec'
      end
      it "sets the :color option" do
        guard.options[:color].should be_false
      end
      it "sets the :recursive option" do
        guard.options[:recursive].should be_false
      end
      it "sets the :paths_for_all_specs option" do
        guard.options[:paths_for_all_specs].should eql ['test']
      end
    end
  end

  describe "#start" do
    context "when :all_on_start is true" do
      it "runs all" do
        guard.should_receive(:run_all)
        guard.start
      end
    end

    context "when :all_on_start is false" do
      let(:guard) { Guard::MochaNode.new([], { :all_on_start => false }) }

      it "does not run all" do
        guard.should_not_receive(:run_all)
        guard.start
      end
    end
  end

  describe "#run_all" do
    it "updates the state with the specs in the spec dir" do
      state.should_receive(:update).with(["spec"], anything)
      guard.run_all
    end

    it "passes the options through to the state" do
      an_option = { :option => "value" }
      guard.options.update(an_option)
      state.should_receive(:update).with(anything, hash_including(an_option))
      guard.run_all
    end

    it "notifies the user with the outcome of running all specs" do
      guard.should_receive(:notify).with(:all)
      guard.run_all
    end
  end

  describe "#run_on_change" do
    before do
      guard.options[:all_after_pass] = false
    end

    it "updates the state with paths" do
      state.should_receive(:update).with(["/a/path"], anything)
      guard.run_on_change(["/a/path"])
    end

    it "passes options through to the state" do
      an_option = { :option => "value" }
      guard.options.update(an_option)
      state.should_receive(:update).with(anything, hash_including(an_option))
      guard.run_on_change
    end

    it "notifies the user with the outcome of running the specs" do
      guard.should_receive(:notify).with(:some)
      guard.run_on_change
    end

    context "when specs pass" do
      before do
        guard.stub(:passing? => true)
      end

      context "and :all_after_pass is true" do
        before do
          guard.options[:all_after_pass] = true
        end

        it "runs all" do
          guard.should_receive(:run_all)
          guard.run_on_change
        end
      end

      context "and :all_after_pass is false" do
        before do
          guard.options[:all_after_pass] = false
        end

        context "if :all_after_pass is true" do
          it "does not run all" do
            guard.should_not_receive(:run_all)
            guard.run_on_change
          end
        end
      end
    end

    context "when there are failing paths" do
      let(:failing_paths) { %w(foo/bar zip/zap) }
      let(:changed_paths) { %w(aaa/bbb ccc/ddd) }
      let(:all_paths)     { failing_paths + changed_paths }

      before do
        guard.stub(:failing_paths => failing_paths)
      end

      context "and :keep_failed is true" do
        before do
          guard.options[:keep_failed] = true
        end

        it "updates state with failing paths and the changed paths" do
          state.should_receive(:update).with(all_paths, anything)
          guard.run_on_change(changed_paths)
        end
      end

      context "and :keep_failed is false" do
        before do
          guard.options[:keep_failed] = false
        end

        it "updates state with only the changed paths" do
          state.should_receive(:update).with(changed_paths, anything)
          guard.run_on_change(changed_paths)
        end
      end
    end
  end
end
