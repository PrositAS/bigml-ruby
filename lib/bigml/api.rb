# encoding: utf-8
#
# Copyright 2014-2016 BigML
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
require 'uri'
#require 'bigml/resourcehandler'
require_relative 'resourcehandler'
require 'pp'

module BigML

  STATUSES = {
    WAITING => "WAITING",
    QUEUED => "QUEUED",
    STARTED => "STARTED",
    IN_PROGRESS => "IN_PROGRESS",
    SUMMARIZED => "SUMMARIZED",
    FINISHED => "FINISHED",
    UPLOADING => "UPLOADING",
    FAULTY => "FAULTY",
    UNKNOWN => "UNKNOWN",
    RUNNABLE => "RUNNABLE"
  }

  ID_GETTERS = {
    "project" => "BigML::get_project_id",
    "source" => "get_source_id",
    "dataset" => "get_dataset_id",
    "model" => "get_model_id",
    "ensemble" => "get_ensemble_id",
    "logisticregression" => "get_logisticregression_id",
    "deepnet" => "get_deepnet_id",
    "evaluation" => "get_evaluation_id",
    "cluster" => "get_cluster_id",
    "anomaly" => "get_anomaly_id",
    "topicmodel" => "get_topic_model_id",
    "association" => "get_association_id",
    "timeseries" => "get_time_series_id",
    "optiml" => "get_optiml_id",
    "fusion" => "get_fusion_id",
    "prediction" => "get_prediction_id",
    "centroid" => "get_centroid_id",
    "anomalyscore" => "get_anomaly_score_id",
    "topicdistribution" => "get_topic_distribution_id",
    "associationset" => "get_association_set_id",
    "bathprediction" => "get_batch_prediction_id",
    "batchcentroid" => "get_batch_centroid_id",
    "batchanomalyscore" => "get_batch_anomaly_score_id",
    "batchtopicdistribution" => "get_batch_topic_distribution_id",
    "forecast" => "get_forecast_id",
    "correlation" => "get_correlation_id",
    "statisticaltest" => "get_statistical_test_id",
    "sample" => "get_sample_id",
    "configuration" => "get_configuration_id",
    "script" => "get_script_id",
    "library" => "get_library_id",
    "execution" => "get_execution_id"
  }
  
  def count(listing)
    # Count of existing resources
    if listing.key?('meta') and listing['meta'].key?('query_total')
      return listing['meta']['query_total']
    end
  end

  class Api < ResourceHandler

     attr_reader :storage
     # Initializes the BigML API.
     
     #   If left unspecified, `username` and `api_key` will default to the
     #    values of the `BIGML_USERNAME` and `BIGML_API_KEY` environment
     #    variables respectively.
    
     #    If `dev_mode` is set to `True`, the API will be used in development
     #    mode where the size of your datasets are limited but you are not
     #    charged any credits.
      
     #    If storage is set to a directory name, the resources obtained in
     #    CRU operations will be stored in the given directory.
     #   If domain is set, the api will point to the specified domain. Default
     #    will be the one in the environment variable `BIGML_DOMAIN` or
     #  `bigml.io` if missing. The expected domain argument is a string or a
     #   Domain object. See Domain class for details.
    
     #    When project is set to a project ID,
     #    the user is considered to be working in an
     #    organization project. The scope of the API requests will be limited
     #    to this project and permissions should be previously given by the
     #    organization administrator.
     
     #    When organization is set to an organization ID,
     #    the user is considered to be working for an
     #    organization. The scope of the API requests will be limited to the
     #    projects of the organization and permissions need to be previously
     #    given by the organization administrator.
     
     def initialize(username = nil, api_key = nil, dev_mode = false, 
                    debug = false, set_locale = false, storage = nil, domain = nil,
                    project=nil, organization=nil)
         super(username, api_key, dev_mode, debug, set_locale, storage, domain,project, organization)
         @source_url = @url + SOURCE_PATH
         @project_url = @url + PROJECT_PATH
         @dataset_url = @url + DATASET_PATH
         @model_url = @url + MODEL_PATH
         @prediction_url = @url + PREDICTION_PATH
         @batch_prediction_url = @url + BATCH_PREDICTION_PATH
         @cluster_url = @url + CLUSTER_PATH
         @centroid_url = @url + CENTROID_PATH
         @batch_centroid_url = @url + BATCH_CENTROID_PATH 
         @ensemble_url = @url + ENSEMBLE_PATH
         @anomaly_url = @url + ANOMALY_PATH
         @anomaly_score_url = @url + ANOMALY_SCORE_PATH
         @association_url = @url + ASSOCIATION_PATH
         @association_set_url = @url + ASSOCIATION_SET_PATH
         @batch_anomaly_score_url = @url + BATCH_ANOMALY_SCORE_PATH
         @correlation_url = @url + CORRELATION_PATH
         @evaluation_url = @url + EVALUATION_PATH
         @logistic_regression_url = @url + LOGISTIC_REGRESSION_PATH
         @sample_url = @url + SAMPLE_PATH   
         @statistical_test_url = @url + STATISTICAL_TEST_PATH
         @script_url = @url + SCRIPT_PATH
         @library_url = @url + LIBRARY_PATH
         @execution_url = @url + EXECUTION_PATH
         @topic_model_url = @url + TOPIC_MODEL_PATH
         @topic_distribution_url = @url + TOPIC_DISTRIBUTION_PATH
         @batch_topic_distribution_url = @url + BATCH_TOPIC_DISTRIBUTION_PATH
         @time_series_url = @url + TIME_SERIES_PATH
         @forecast_url = @url + FORECAST_PATH
         @deepnet_url = @url + DEEPNET_PATH
         @configuration_url = @url + CONFIGURATION_PATH
         @optiml_url = @url+OPTIML_PATH
         @fusion_url = @url+FUSION_PATH
     end
     
     def connection_info()
       # Printable string: domain where the connection is bound and the
       # credentials used.
       info = "Connecting to:\n"
       info += "    %s\n" % self.general_domain
       if @general_protocol != BigML::Domain::BIGML_PROTOCOL
          info += "    using %s protocol\n" % @general_protocol
       end
       
       info += "    SSL verification %s\n" % @verify ? "on" : "off"
       if @debug
         info += "    Debug on\n"
       end
       
       if @general_domain != @prediction_domain
         info += "    %s (predictions only)\n" % @prediction_domain
         if self.prediction_protocol != BigML::Domain::BIGML_PROTOCOL
            info += "    using %s protocol\n" % @prediction_protocol
         end
         
         info += "    SSL verification %s\n" % @verify_prediction ? "on" : "off"

       end 
       
       if !@project.blank? or !@organization.blank?
         info += "    Scope info:%s\n                %s\n" % 
                    [@organization.blank? ? "" : @organization, @project.blank? ? "" : @project]
       end 
       
       info += "\nAuthentication string:\n"
       info += "    %s\n" % self.auth[1..-1]
       return info
       
     end 


     def get_fields(resource)
        # Retrieve fields used by a resource.
        # Returns a dictionary with the fields that uses
        # the resource keyed by Id.
       
        def self._get_fields_key(resource, resource_id)
            #Returns the fields key from a resource dict

            if [HTTP_OK, HTTP_ACCEPTED].include?(resource['code'])
                if (MODEL_RE.match(resource_id) or
                        ANOMALY_RE.match(resource_id))
                    return resource['object']['model']['model_fields']
                elsif CLUSTER_RE.match(resource_id)
                    return resource['object']['clusters']['fields']
                elsif CORRELATION_RE.match(resource_id)
                    return resource['object']['correlations']['fields']
                elsif STATISTICAL_TEST_RE.match(resource_id)
                    return resource['object']['statistical_tests']['fields']
                elsif STATISTICAL_TEST_RE.match(resource_id)
                    return resource['object']['statistical_tests']['fields']
                elsif LOGISTIC_REGRESSION_RE.match(resource_id)
                    return resource['object']['logistic_regression']['fields']
                elsif ASSOCIATION_RE.match(resource_id)
                    return resource['object']['associations']['fields']
                elsif TOPIC_MODEL_RE.match(resource_id)
                    return resource['object']['topic_model']['fields']
                elsif TIME_SERIES_RE.match(resource_id)
                    return resource['object']['time_series']['fields']
                elsif DEEPNET_RE.match(resource_id)
                    return resource['object']['deepnet']['fields']
                elsif SAMPLE_RE.match(resource_id)
                    dict = {}
                    resource['object']['sample']['fields'].each do |field|
                      dict[field['id']] = field
                    end

                    return dict
 
                else
                    return resource['object']['fields']
                end
            end

            return nil
        end

        if resource.is_a?(Hash) and resource.key?('resource')
            resource_id = resource['resource']
        elsif (resource.is_a?(String) and (
                SOURCE_RE.match(resource) or DATASET_RE.match(resource) or
                MODEL_RE.match(resource) or PREDICTION_RE.match(resource)))
            resource_id = resource
            resource = _get("%s%s" % [@url, resource_id])
        else
            puts "Wrong resource id"
            return
        end
        
        # Tries to extract fields information from resource dict. If it fails,
        # a get remote call is used to retrieve the resource by id.
        fields = nil
        begin 
            fields = _get_fields_key(resource, resource_id)
        rescue Exception
            resource = _get("%s%s" % [@url, resource_id])
            fields = _get_fields_key(resource, resource_id)
        end

        return fields

     end

     def pprint(resource, out=$stdout)
        #Pretty prints a resource or part of it.
        if resource.is_a?(Hash) and 
           resource.key?('object') and
           resource.key?('resource')

           resource_id = resource['resource']
           if (SOURCE_RE.match(resource_id) or DATASET_RE.match(resource_id) or 
               MODEL_RE.match(resource_id) or EVALUATION_RE.match(resource_id) or
               ENSEMBLE_RE.match(resource_id) or CLUSTER_RE.match(resource_id) or
               ANOMALY_RE.match(resource_id) or TOPIC_MODEL_RE.match(resource_id) or 
	       LOGISTIC_REGRESSION_RE.match(resource_id) or TIME_SERIES_RE.match(resource_id) or
	       DEEPNET_RE.match(resource_id) or FUSION_RE.match(resource_id) or OPTIML_RE.match(resource_id))

              out.puts "%s (%s bytes)" % [resource['object']['name'], resource['object']['size']]

           elsif PREDICTION_RE.match(resource['resource'])
              objective_field_name = resource['object']['fields'][resource['object']['objective_fields'][0]]['name']
              input_data = {}
              
              resource['object']['input_data'].each do |key, value| 
                begin
                   name = resource['object']['fields'][key]['name']

                rescue Exception
                   name=key
                end
                input_data[name] = value
              end

              prediction = resource['object']['prediction'][resource['object']['objective_fields'][0]]
              out.puts "%s for %s is %s" % [objective_field_name, input_data, prediction]
           end
           out.flush

        else
           pp(resource, out, 4)
        end
 
     end

     def status(resource)
        # Maps status code to string.
        resource_id = BigML::get_resource_id(resource)
        unless resource_id.nil?
            resource = _get("%s%s" % [@url, resource_id])
            status = BigML::Util::get_status(resource)
            code = status['code']
            return STATUSES.fetch(code, "UNKNOWN")
        else
            status = BigML::Util::get_status(resource)
            if status['code'] != UPLOADING
                puts "Wrong resource id"
                return
            end
            return STATUSES[UPLOADING]
        end
     end
     
     def check_resource(resource, query_string='', wait_time=1)
      # Check resource method.                                
      return BigML::check_resource(resource,nil,query_string, wait_time, nil, false, self)
     end
     ##########################################################################
     #
     # Sources
     # https://bigml.com/developers/sources
     #
     ########################################################################## 

     def _create_remote_source(url, args=nil)
        #Creates a new source using a URL
        create_args = args.nil? ? {} : args.clone
        create_args["remote"]=url
        body = JSON.generate(create_args)
  
        return _create(@source_url, body)
     end

     def _create_local_source(file_name, args=nil)
        # Creates a new source using a local file.
        # This function is only used from Python 3. No async-prepared.
        create_args = {}
        unless args.nil?
          create_args = args.clone
        end

        create_args.each do |key, value|
           if (!value.nil? and  (value.is_a?(Array) or value.is_a?(Hash)))
              create_args[key] = JSON.generate(value)
           end
        end

        code = HTTP_INTERNAL_SERVER_ERROR
        resource_id = nil 
        location = nil 
        resource = nil 
        error = {"status" => {"code" => code, "message" =>  "The resource couldn't be created"}}

        begin
           if file_name.is_a?(String)
              file=File.new(file_name, 'rb')
           else
              file=file_name
           end
        rescue Exception
          abort("ERROR: cannot read training set")
        end

        create_args['file']=file
        begin
           response = RestClient.post @source_url+@auth, create_args
        rescue RestClient::RequestTimeout
           raise Exception, 'Request Timeout'
        rescue RestClient::Exception
           code = HTTP_INTERNAL_SERVER_ERROR
           return Util::maybe_save(resource_id, @storage, code,
                             location, resource, error)
        end

        code = response.code
        if code == HTTP_CREATED
           location = response.headers.fetch('location', "")
           resource = JSON.parse(response.to_str)
           resource_id = resource["resource"]
           error = nil 
        elsif [HTTP_BAD_REQUEST, HTTP_UNAUTHORIZED, HTTP_PAYMENT_REQUIRED, HTTP_NOT_FOUND, HTTP_TOO_MANY_REQUESTS].include?(code)
            error = JSON.parse(response.to_str)#'utf-8'
        else
          code = HTTP_INTERNAL_SERVER_ERROR
        end

        return Util::maybe_save(resource_id, @storage, code, location, resource, error)
     end

     def create_source(path=nil, args=nil, async=false,
                       progress_bar=false, out=$stdout)
       # Creates a new source.
       # The source can be a local file path or a URL.
 
       if path.nil?
          raise Exception, 'A local path or a valid URL must be provided.'
       end
 
       if Util.is_url(path)
          return _create_remote_source(path, args)
       else
          return _create_local_source(path, args)
       end
       
     end

     def get_source(source, query_string='')
        # Retrieves a remote source.
        #   The source parameter should be a string containing the
        #   source id or the dict returned by create_source.
        #   As source is an evolving object that is processed
        #   until it reaches the FINISHED or FAULTY state, thet function will
        #   return a dict that encloses the source values and state info
        #   available at the time it is called.
        BigML::check_resource_type(source, SOURCE_PATH, "A source id is needed.")
        source_id = BigML::get_source_id(source)
        unless source_id.nil?
          return _get(@url+source_id, query_string)
        end
     end

     def source_is_ready(source)
       #Checks whether a source' status is FINISHED.
       BigML::check_resource_type(source, SOURCE_PATH, "A source id is needed.")
       source = get_source(source)
       return resource_is_ready(source)
     end

     def list_sources(query_string='')
       # Lists all your remote sources.
       return _list(@source_url, query_string)
     end 
    
     def update_source(source, changes)
       #Updates a source.
       # Updates remote `source` with `changes'.
       BigML::check_resource_type(source, SOURCE_PATH, "A source id is needed.")
       source_id = BigML::get_source_id(source)
       unless source_id.nil?
          return _update(@url+source_id, JSON.generate(changes))
       end
     end
 
     def delete_source(source)
       #Deletes a remote source permanently.
       BigML::check_resource_type(source, SOURCE_PATH, "A source id is needed.")
       source_id = BigML::get_source_id(source)
       unless source_id.nil?
          return _delete(@url+source_id)
       end
     end
     
     ##########################################################################
     #
     # Datasets
     # https://bigml.com/developers/datasets
     #
     ########################################################################## 
     def create_dataset(origin_resource, args=nil,
                        wait_time=3, retries=10)
  
       #Creates a remote dataset.

       # Uses a remote resource to create a new dataset using the
       # arguments in `args`.
       # The allowed remote resources can be:
       #     - source
       #     - dataset
       #     - list of datasets
       #     - cluster
       # In the case of using cluster id as origin_resources, a centroid must
       # also be provided in the args argument. The first centroid is used
       # otherwise.
       # If `wait_time` is higher than 0 then the dataset creation
       # request is not sent until the `source` has been created successfuly.
       #
       create_args=args.nil? ? {} : args.clone

       if origin_resource.is_a?(Array)
         # mutidatasets
         create_args=_set_create_from_datasets_args(origin_resource, 
                                                    create_args,
                                                    wait_time,
                                                    retries,
                                                    'origin_datasets')
       else
          resource_type = BigML::get_resource_type(origin_resource)
          # dataset from source
          if resource_type == SOURCE_PATH
             source_id = BigML::get_source_id(origin_resource)
             unless source_id.nil?
               BigML::check_resource(source_id, nil, BigML::TINY_RESOURCE,
                                     wait_time, retries,
                                     true, self)

               create_args["source"] = source_id 
             end
          # dataset from dataset
          elsif resource_type == DATASET_PATH
             create_args = _set_create_from_datasets_args(origin_resource, 
			                                  create_args, 
                                                          wait_time,
                                                          retries, "origin_dataset")
          # dataset from cluster and centroid
          elsif resource_type == CLUSTER_PATH
             cluster_id = BigML::get_cluster_id(origin_resource)
             cluster = BigML::check_resource(cluster_id, nil, BigML::TINY_RESOURCE,
                                             wait_time,
                                             retries,
                                             true, self)

             unless create_args.key?('centroid')
               begin
                   
                   centroid = cluster['object']['cluster_datasets_ids'].keys[0]
                   create_args["centroid"] = centroid
               rescue Exception
 		 raise ArgumentError, "Failed to generate the dataset. A centroid id is needed in the args argument to generate a dataset from a cluster."
               end 
             end

             create_args["cluster"]=cluster_id

          else
             raise Exception, "A source, dataset, list of dataset ids or cluster id plus centroid id are needed to create a dataset. "+resource_type + "found."
          end
       end

       body = JSON.generate(create_args)
       return _create(@dataset_url, body)

     end

     def get_dataset(dataset, query_string='')
        #Retrieves a dataset.

        #The dataset parameter should be a string containing the
        # dataset id or the dict returned by create_dataset.
        # As dataset is an evolving object that is processed
        # until it reaches the FINISHED or FAULTY state, the function will
        # return a dict that encloses the dataset values and state info
        # available at the time it is called.
   
        BigML::check_resource_type(dataset, DATASET_PATH, "A dataset id is needed.")
        dataset_id = BigML::get_dataset_id(dataset)

        unless dataset_id.nil?
          return _get(@url+dataset_id, query_string)
        end
     end

     def dataset_is_ready(dataset)
       #Check whether a dataset' status is FINISHED.
       BigML::check_resource_type(dataset, DATASET_PATH, "A dataset id is needed.")
       dataset = get_dataset(dataset)
       return resource_is_ready(dataset)
     end

     def list_datasets(query_string='')
       # Lists all your remote datasets.
       return _list(@dataset_url, query_string)
     end

     def update_dataset(dataset, changes)
       # Updates a dataset.
       # Updates remote `dataset` with `changes'.
       BigML::check_resource_type(dataset, DATASET_PATH, "A dataset id is needed.")
       dataset_id = BigML::get_dataset_id(dataset)
       unless dataset_id.nil?
          return _update(@url+dataset_id, JSON.generate(changes))
       end
     end  

     def delete_dataset(dataset)
       #Deletes a remote dataset permanently.
       BigML::check_resource_type(dataset, DATASET_PATH, "A dataset id is needed.")
       dataset_id = BigML::get_dataset_id(dataset)
       unless dataset_id.nil?
          return _delete(@url+datasetid)
       end
     end
  
     def error_counts(dataset, raise_on_error=true)
       # Returns the ids of the fields that contain errors and their number.

       # The dataset argument can be either a dataset resource structure
       # or a dataset id (that will be used to retrieve the associated
       # remote resource).

       errors_dict = {}
       if !dataset.is_a?(Hash) or !dataset.key?('object') 
          BigML::check_resource_type(dataset, DATASET_PATH, "A dataset id is needed.") 
          dataset_id = BigML::get_dataset_id(dataset)
          dataset = BigML::check_resource(dataset_id, self.method("get_dataset"), '',
                                          1, raise_on_error, nil)
 
          if !raise_on_error and !dataset['error'].nil?
             dataset_id=nil
          end

       else
          dataset_id = BigML::get_dataset_id(dataset)
       end
      
       unless dataset_id.nil?
          errors = dataset.fetch('object', {}).fetch('status', {}).fetch('field_errors', {})
          errors.each do |field_id, value| 
            errors_dict[field_id] = errors[field_id]['total']
          end

       end
       
       return errors_dict

     end

     def download_dataset(dataset, filename=nil, retries=10)
        #Donwloads dataset contents to a csv file or file object

        BigML::check_resource_type(dataset, DATASET_PATH, "A dataset id is needed.")
        dataset_id = BigML::get_dataset_id(dataset)
        unless dataset_id.nil?
            return _download(@url+dataset_id+DOWNLOAD_DIR, filename, 10, retries)
        end
     end

     ##########################################################################
     #
     # Models
     # https://bigml.com/developers/models
     #
     ########################################################################## 
     def create_model(origin_resource, args=nil,
                        wait_time=3, retries=10)
       #Creates a model from an origin_resource.

       # Uses a remote resource to create a new model using the
       # arguments in `args`.
       # The allowed remote resources can be:
       #     - dataset
       #     - list of datasets
       #     - cluster
       # In the case of using cluster id as origin_resource, a centroid must
       # also be provided in the args argument. The first centroid is used
       # otherwise.
       create_args=args.nil? ? {} : args.clone

       if origin_resource.is_a?(Array)
         # mutidatasets
         create_args=_set_create_from_datasets_args(origin_resource,
                                                    create_args,
                                                    wait_time,
                                                    retries, nil)
       else
          resource_type = BigML::get_resource_type(origin_resource)
          if resource_type == CLUSTER_PATH
             cluster_id = BigML::get_cluster_id(origin_resource)
             cluster = BigML::check_resource(cluster_id, nil, BigML::TINY_RESOURCE,
                                             wait_time,
                                             retries,
                                             true, self)

             unless create_args.key?('centroid')
               begin

                   centroid = cluster['object']['cluster_models'].keys[0]
                   create_args["centroid"] = centroid
               rescue Exception
                 raise ArgumentError, "Failed to generate the model. A centroid id is needed in the args argument to generate a model from a cluster."
               end
             end

             create_args["cluster"]=cluster_id

          elsif resource_type == DATASET_PATH
             create_args=_set_create_from_datasets_args(origin_resource,
                                                        create_args,
                                                        wait_time,
                                                        retries,
                                                        nil)

          else
             raise Exception, "A dataset, list of dataset ids or cluster id plus centroid id are needed to create a model. "+resource_type + " found."
          end

       end
       body = JSON.generate(create_args)
       return _create(@model_url, body)

     end
 
     def get_model(model,  query_string='',
                  shared_username=nil, shared_api_key=nil)
        #Retrieves a cluster

        BigML::check_resource_type(model, MODEL_PATH, "A model id is needed.")
        model_id = BigML::get_model_id(model)

        unless model_id.nil?
          return _get(@url+model_id, query_string, shared_username, shared_api_key)
        end
     end

     def model_is_ready(model, args={})
       #Check whether a model status is FINISHED.
       BigML::check_resource_type(model, MODEL_PATH, "A model id is needed.")
       model = get_model(model, args.fetch("query_string", nil),
                         args.fetch("shared_username", nil),
                         args.fetch("shared_api_key", nil))
       return resource_is_ready(model)
     end

     def list_models(query_string='')
       # Lists all your remote models.
       return _list(@model_url, query_string)
     end

     def update_model(model, changes)
       # Updates a model.
       # Updates remote `model` with `changes'.
       BigML::check_resource_type(model, MODEL_PATH, "A model id is needed.")
       model_id = BigML::get_model_id(model)
       unless model_id.nil?
          return _update(@url+model_id, JSON.generate(changes))
       end
     end

     def delete_model(model)
       #Deletes a remote model permanently.
       BigML::check_resource_type(model, MODEL_PATH, "A model id is needed.")
       model_id = BigML::get_model_id(model)
       unless model_id.nil?
          return _delete(@url+modelid)
       end
     end
     
     ##########################################################################
     #
     # Predictions
     # https://bigml.com/developers/predictions
     ##########################################################################

     def create_prediction(model, input_data=nil,
                           args=nil, wait_time=3, retries=10)
       # Creates a new prediction.
       # The model parameter can be:
       # - a simple tree model
       # - a simple logistic regression model
       # - an ensemble
       # - a deepnet
       # - a fusion
       # The by_name argument is now deprecated. It will be removed.

       model_id = nil

       resource_type = BigML::get_resource_type(model)
       
       if !SUPERVISED_PATHS.include?(resource_type)
         raise Exception, "A supervised model resource id is needed to create a prediction. %s found. " % resource_type
       end
       
       model_id = BigML::get_resource_id(model)
       
       if !model_id.nil?
         BigML::check_resource(model_id, nil, BigML::TINY_RESOURCE,
                               wait_time, retries,
                               true, self)
       end 
       
       input_data = input_data.nil? ? {} : input_data 
       create_args = {}
       unless args.nil?
         create_args=args.clone
       end

       create_args["input_data"] = input_data
       
       if !model_id.nil?
         create_args["model"] = model_id 
       end
       
       body = JSON.generate(create_args)

       return _create(@prediction_url, body, @verify)  

     end

     def get_prediction(prediction,  query_string='')
        #Retrieves a prediction

        BigML::check_resource_type(prediction, PREDICTION_PATH, "A prediction id is needed.")
        prediction_id = BigML::get_prediction_id(prediction)

        unless prediction_id.nil?
          return _get(@url+predicion_id, query_string)
        end
     end

     def list_predictions(query_string='')
       # Lists all your remote predictions.
       return _list(@prediction_url, query_string)
     end

     def update_prediction(prediction, changes)
       # Updates a prediction.
       # Updates remote `prediction` with `changes'.
       BigML::check_resource_type(prediction, PREDICTION_PATH, "A prediction id is needed.")
       prediction_id = BigML::get_prediction_id(prediction)
       unless prediction_id.nil?
          return _update(@url+prediction_id, JSON.generate(changes))
       end
     end

     def delete_prediction(prediction)
       #Deletes a remote prediction permanently.
       BigML::check_resource_type(prediction, PREDICTION_PATH, "A prediction id is needed.")
       prediction_id = BigML::get_prediction_id(prediction)
       unless prediction_id.nil?
          return _delete(@url+prediction_id)
       end
     end

     ##########################################################################
     #
     # Clusters
     # https://bigml.com/developers/clusters
     ##########################################################################
     def create_cluster(datasets, args=nil, wait_time=3, retries=10)
        #Creates a cluster from a `dataset` or a list o `datasets`.

        create_args = _set_create_from_datasets_args(datasets,args, 
                                                     wait_time, retries, nil)

        body = JSON.generate(create_args)
        return _create(@cluster_url, body)
     end

     def get_cluster(cluster, query_string='',
                     shared_username=nil, shared_api_key=nil)
        #Retrieves a cluster 

        BigML::check_resource_type(cluster, CLUSTER_PATH, "A cluster id is needed.")
        cluster_id = BigML::get_cluster_id(cluster)

        unless cluster_id.nil?
          return _get(@url+cluster_id, query_string,
                     shared_username, shared_api_key)
        end
     end
 
     def cluster_is_ready(cluster, args={})
       #Check whether a cluster status is FINISHED.
       BigML::check_resource_type(cluster, CLUSTER_PATH, "A cluster id is needed.")
       cluster = get_cluster(cluster, args.fetch("query_string", nil),
                         args.fetch("shared_username", nil),
                         args.fetch("shared_api_key", nil))
       return resource_is_ready(cluster)
     end

     def list_clusters(query_string='')
       # Lists all your remote clusters 
       return _list(@cluster_url, query_string)
     end

     def update_cluster(cluster, changes)
       # Updates a cluster.
       # Updates remote `cluster` with `changes'.
       BigML::check_resource_type(cluster, CLUSTER_PATH, "A clusterid is needed.")
       cluster_id = BigML::get_cluster_id(cluster)
       unless cluster_id.nil?
          return _update(@url+cluster_id, JSON.generate(changes))
       end
     end

     def delete_cluster(cluster)
       #Deletes a remote cluster permanently.
       BigML::check_resource_type(cluster, CLUSTER_PATH, "A cluster id is needed.")
       cluster_id = BigML::get_cluster_id(cluster)
       unless cluster_id.nil?
          return _delete(@url+cluster_id)
       end
     end

     ##########################################################################
     #
     # Centroids
     # https://bigml.com/developers/centroids
     ##########################################################################
     def create_centroid(cluster, input_data=nil,
                         args=nil, wait_time=3, retries=10)
        #Creates a new centroid.
        cluster_id = nil
        resource_type = BigML::get_resource_type(cluster)
        if resource_type == CLUSTER_PATH
            cluster_id = BigML::get_cluster_id(cluster)
            BigML::check_resource(cluster_id, nil,
                                  BigML::TINY_RESOURCE,
                                  wait_time,retries,
                                  true, self)
        else
            raise Exception, "A cluster id is needed to create a centroid. "+resource_type + ". found" 
        end

        input_data = input_data.nil? ? {} : input_data.clone
        create_args = args.nil? ? {} : args
        create_args["input_data"] = input_data
        create_args["cluster"] = cluster_id
      
        body = JSON.generate(create_args)
        return _create(@centroid_url, body, @verify)
     end
 
     def get_centroid(centroid,  query_string='')
        #Retrieves a centroid

        BigML::check_resource_type(centroid, CENTROID_PATH, "A centroid id is needed.")
        centroid_id = BigML::get_centroid_id(centroid)

        unless centroid_id.nil?
          return _get(@url+centroid_id, query_string)
        end
     end

     def list_centroids(query_string='')
       # Lists all your remote centroids.
       return _list(@centroid_url, query_string)
     end

     def update_centroid(centroid, changes)
       # Updates a centroid.
       # Updates remote `centroid` with `changes'.
       BigML::check_resource_type(centroid, CENTROID_PATH, "A centroid id is needed.")
       centroid_id = BigML::get_centroid_id(centroid)
       unless centroid_id.nil?
          return _update(@url+centroid_id, JSON.generate(changes))
       end
     end

     def delete_centroid(centroid)
       #Deletes a remote centroid permanently.
       BigML::check_resource_type(centroid, CENTROID_PATH, "A centroid id is needed.")
       centroid_id = BigML::get_centroid_id(centroid)
       unless centroid_id.nil?
          return _delete(@url+centroid_id)
       end
     end

     ##########################################################################
     #
     # Ensembles
     # https://bigml.com/developers/ensembles
     ##########################################################################

     def create_ensemble(datasets, args=nil, wait_time=3, retries=10)
        #Creates a ensemble from a `dataset` or a list o `datasets`.

        create_args = _set_create_from_datasets_args(datasets,args,
                                                     wait_time, retries, nil)

        body = JSON.generate(create_args)
        return _create(@ensemble_url, body)
     end

     def get_ensemble(ensemble, query_string='', shared_username=nil, shared_api_key=nil)
        #Retrieves a prediction

        BigML::check_resource_type(ensemble, ENSEMBLE_PATH, "A ensemble id is needed.")
        ensemble_id = BigML::get_ensemble_id(ensemble)

        unless ensemble_id.nil?
          return _get(@url+ensemble_id, query_string)
        end
     end

     def ensemble_is_ready(ensemble, args={})
       #Check whether a ensemble status is FINISHED.
       BigML::check_resource_type(ensemble, ENSEMBLE_PATH, "A ensemble id is needed.")
       ensemble = get_ensemble(ensemble, args.fetch("query_string", nil))
       return resource_is_ready(ensemble)
     end

     def list_ensembles(query_string='')
       # Lists all your remote ensembles 
       return _list(@ensemble_url, query_string)
     end

     def update_ensemble(ensemble, changes)
       # Updates a ensemble.
       # Updates remote `ensemble` with `changes'.
       BigML::check_resource_type(ensemble, ENSEMBLE_PATH, "A ensembleid is needed.")
       ensemble_id = BigML::get_ensemble_id(ensemble)
       unless ensemble_id.nil?
          return _update(@url+ensemble_id, JSON.generate(changes))
       end
     end

     def delete_ensemble(ensemble)
       #Deletes a remote ensemble permanently.
       BigML::check_resource_type(ensemble, ENSEMBLE_PATH, "A ensemble id is needed.")
       ensemble_id = BigML::get_ensemble_id(ensemble)
       unless ensemble_id.nil?
          return _delete(@url+ensemble_id)
       end
     end

     ##########################################################################
     #
     # Anomalies 
     # https://bigml.com/developers/anomalies
     ##########################################################################

     def create_anomaly(datasets, args=nil, wait_time=3, retries=10)
       #Creates a anomaly from a `dataset` or a list o `datasets`.

       create_args = _set_create_from_datasets_args(datasets,args,
                                                    wait_time, retries, nil)

       body = JSON.generate(create_args)
       return _create(@anomaly_url, body)
     end
     
     def get_anomaly(anomaly, query_string='',
                     shared_username=nil, shared_api_key=nil)
        #Retrieves a anomaly 

        BigML::check_resource_type(anomaly, ANOMALY_PATH, "A anomaly id is needed.")
        anomaly_id = BigML::get_anomaly_id(anomaly)

        unless anomaly_id.nil?
          return _get(@url+anomaly_id, query_string,
                     shared_username, shared_api_key)
        end
     end

     def anomaly_is_ready(anomaly, args={})
       #Check whether a anomaly status is FINISHED.
       BigML::check_resource_type(anomaly, ANOMALY_PATH, "A anomaly id is needed.")
       anomaly = get_anomaly(anomaly, args.fetch("query_string", nil),
                         args.fetch("shared_username", nil),
                         args.fetch("shared_api_key", nil))
       return resource_is_ready(anomaly)
     end

     def list_anomalies(query_string='')
       # Lists all your remote anomalies 
       return _list(@anomaly_url, query_string)
     end

     def update_anomaly(anomaly, changes)
       # Updates a anomaly.
       # Updates remote `anomaly` with `changes'.
       BigML::check_resource_type(anomaly, ANOMALY_PATH, "A anomalyid is needed.")
       anomaly_id = BigML::get_anomaly_id(anomaly)
       unless anomaly_id.nil?
          return _update(@url+anomaly_id, JSON.generate(changes))
       end
     end

     def delete_anomaly(anomaly)
       #Deletes a remote anomaly permanently.
       BigML::check_resource_type(anomaly, ANOMALY_PATH, "A anomaly id is needed.")
       anomaly_id = BigML::get_anomaly_id(anomaly)
       unless anomaly_id.nil?
          return _delete(@url+anomaly_id)
       end
     end

     ##########################################################################
     #
     # Anomalyscores
     # https://bigml.com/developers//anomalyscores
     ##########################################################################
     def create_anomaly_score(anomaly, input_data=nil,
                             args=nil, wait_time=3, retries=10)
       # Creates a new anomaly score.
       anomaly_id = nil 
       resource_type = BigML::get_resource_type(anomaly)

       if resource_type == ANOMALY_PATH
          anomaly_id = BigML::get_anomaly_id(anomaly)
          BigML::check_resource(anomaly_id, nil,
                                BigML::TINY_RESOURCE,
                                wait_time, retries,
                                true, self)
       else
          raise Exception, "An anomaly detector id is needed to create an  anomaly score. "+ resource_type + " found."
       end
 
       input_data = input_data.nil? ? {} : input_data.clone
       create_args = args.nil? ? {} : args 
       create_args["input_data"] = input_data
       create_args["anomaly"] = anomaly_id 
  
       body = JSON.generate(create_args)
       return _create(@anomaly_score_url, body)

     end

     def get_anomaly_score(anomaly_score, query_string='')
        #Retrieves a anomaly score 

        BigML::check_resource_type(anomaly_score, ANOMALY_SCORE_PATH, "A anomaly score id is needed.")
        anomaly_score_id = BigML::get_anomaly_score_id(anomaly_score)

        unless anomaly_score_id.nil?
          return _get(@url+anomaly_score_id, query_string)
        end
     end

     def list_anomaly_scores(query_string='')
       # Lists all your remote anomaly scores 
       return _list(@anomaly_score_url, query_string)
     end

     def update_anomaly_score(anomaly_score, changes)
       # Updates a anomaly score.
       # Updates remote `anomaly score` with `changes'.
       BigML::check_resource_type(anomaly_score, ANOMALY_SCORE_PATH, "A anomaly score id is needed.")
       anomaly_score_id = BigML::get_anomaly_id(anomaly_score)
       unless anomaly_score_id.nil?
          return _update(@url+anomaly_score_id, JSON.generate(changes))
       end
     end

     def delete_anomaly_score(anomaly_score)
       #Deletes a remote anomaly score permanently.
       BigML::check_resource_type(anomaly_score, ANOMALY_SCORE_PATH, "A anomaly score id is needed.")
       anomaly_score_id = BigML::get_anomaly_score_id(anomaly_score)
       unless anomaly_score_id.nil?
          return _delete(@url+anomaly_score_id)
       end
     end

     ##########################################################################
     #
     # Associations
     # https://bigml.com/developers/associations
     ##########################################################################

     def create_association(datasets, args=nil, wait_time=3, retries=10)
        #Creates a association from a `dataset` or a list o `datasets`.

        create_args = _set_create_from_datasets_args(datasets,args,
                                                     wait_time, retries, nil)

        body = JSON.generate(create_args)
        return _create(@association_url, body)
     end

     def get_association(association, query_string='')
        #Retrieves a prediction
        BigML::check_resource_type(association, ASSOCIATION_PATH, "A association id is needed.")
        association_id = BigML::get_association_id(association)

        unless association_id.nil?
          return _get(@url+association_id, query_string)
        end
     end

     def association_is_ready(association, args={})
       #Check whether a association status is FINISHED.
       BigML::check_resource_type(association, ASSOCIATION_PATH, "A association id is needed.")
       association = get_association(association, args.fetch("query_string", nil))
       return resource_is_ready(association)
     end

     def list_associations(query_string='')
       # Lists all your remote associations 
       return _list(@association_url, query_string)
     end

     def update_association(association, changes)
       # Updates a association.
       # Updates remote `association` with `changes'.
       BigML::check_resource_type(association, ASSOCIATION_PATH, "A associationid is needed.")
       association_id = BigML::get_association_id(association)
       unless association_id.nil?
          return _update(@url+association_id, JSON.generate(changes))
       end
     end 
 
     def delete_association(association)
       #Deletes a remote association permanently.
       BigML::check_resource_type(association, ASSOCIATION_PATH, "A association id is needed.")
       association_id = BigML::get_association_id(association)
       unless association_id.nil?
          return _delete(@url+association_id)
       end
     end

     ##########################################################################
     #
     # Associationset
     # https://bigml.com/developers/associationset
     ##########################################################################

     def create_association_set(association, input_data=nil,
                                args=nil, wait_time=3, retries=10)
       #Creates a new association set.
       association_id = nil 
       resource_type = BigML::get_resource_type(association)

       if resource_type == ASSOCIATION_PATH
          association_id = BigML::get_association_id(association)
          BigML::check_resource(association_id, nil,
                                BigML::TINY_RESOURCE,
                                wait_time, retries,
                                true, self)
       else
           raise Exception, "A association id is needed to create an association set. "+ resource_type + " found."
       end
     
       input_data = input_data.nil? ? {} : input_data.clone
       create_args = args.nil? ? {} : args
       create_args["input_data"] = input_data
       create_args["association"] = association_id

       body = JSON.generate(create_args)
       return _create(@association_set_url, body)

     end

     def get_association_set(association_set, query_string='')
        #Retrieves a prediction

        BigML::check_resource_type(association_set, ASSOCIATION_SET_PATH, "A association set id is needed.")
        association_set_id = BigML::get_association_set_id(association_set)

        unless association_set_id.nil?
          return _get(@url+association_set_id, query_string)
        end
     end

     def list_association_sets(query_string='')
       # Lists all your remote association_sets 
       return _list(@association_set_url, query_string)
     end

     def update_association_set(association_set, changes)
       # Updates a association_set.
       # Updates remote `association_set` with `changes'.
       BigML::check_resource_type(association_set, ASSOCIATION_SET_PATH, "A association set id is needed.")
       association_set_id = BigML::get_association_set_id(association_set)
       unless association_set_id.nil?
          return _update(@url+association_set_id, JSON.generate(changes))
       end
     end

     def delete_association_set(association_set)
       #Deletes a remote association_set permanently.
       BigML::check_resource_type(association_set, ASSOCIATION_SET_PATH, "A association set id is needed.")
       association_set_id = BigML::get_association_set_id(association_set)
       unless association_set_id.nil?
          return _delete(@url+association_set_id)
       end
     end

     ##########################################################################
     #
     # Batch Anomalys Scores
     # https://bigml.com/developers/batchanomalyscores
     ##########################################################################

     def create_batch_anomaly_score(anomaly, dataset,
                                   args=nil, wait_time=3, retries=10)

       # Creates a new batch anomaly score.
       create_args = args.nil? ? {} : args.clone

       origin_resources_checked = check_origins(dataset, anomaly, create_args,
                                                [ANOMALY_PATH], wait_time, retries) 
       if origin_resources_checked
          body = JSON.generate(create_args)
          return _create(@batch_anomaly_score_url, body)
       end

     end

     def download_batch_anomaly_score(batch_anomaly_score, filename=nil)
        BigML::check_resource_type(batch_anomaly_score, BATCH_ANOMALY_SCORE_PATH, "A anomaly batch scoreid is needed.")
        anomaly_batch_score_id = BigML::get_batch_anomaly_score_id(batch_anomaly_score)
        unless anomaly_batch_score_id.nil?
          return _download(@url+anomaly_batch_score_id+DOWNLOAD_DIR, filename)
        end   
     end

     def get_batch_anomaly_score(anomaly_batch_score, query_string='')
        #Retrieves a anomaly batch score 

        BigML::check_resource_type(anomaly_batch_score, BATCH_ANOMALY_SCORE_PATH, "A anomaly batch score id is needed.")
        anomaly_batch_score_id = BigML::get_anomaly_batch_score_id(anomaly_batch_score)

        unless anomaly_batch_score_id.nil?
          return _get(@url+anomaly_batch_score_id, query_string)
        end
     end

     def list_batch_anomaly_scores(query_string='')
       # Lists all your remote batch  anomaly scores
       return _list(@batch_anomaly_score_url, query_string)
     end

     def update_anomaly_batch_score(anomaly_batch_score, changes)
       # Updates a anomaly batch score.
       # Updates remote `anomaly batch score` with `changes'.
       BigML::check_resource_type(anomaly_batch_score, BATCH_ANOMALY_SCORE_PATH, "A anomaly batch scoreid is needed.")
       anomaly_batch_score_id = BigML::get_anomaly_batch_score_id(anomaly_batch_score)
       unless anomaly_batch_score_id.nil?
          return _update(@url+anomaly_batch_score_id, JSON.generate(changes))
       end
     end

     def delete_anomaly_batch_score(anomaly_batch_score)
       #Deletes a remote anomaly batch score permanently.
       BigML::check_resource_type(anomaly_batch_score, BATCH_ANOMALY_SCORE_PATH, "A anomaly batch score id is needed.")
       anomaly_batch_score_id = BigML::get_anomaly_batch_score_id(anomaly_batch_score)
       unless anomaly_batch_score_id.nil?
          return _delete(@url+anomaly_batch_score_id)
       end
     end

     ##########################################################################
     #
     # Batch Centroid
     # https://bigml.com/developers/batchcentroid
     ##########################################################################

     def create_batch_centroid(cluster, dataset,
                               args=nil, wait_time=3, retries=10)
       # Creates a new batch centroid.
       create_args = args.nil? ? {} : args.clone 

        origin_resources_checked = check_origins(dataset, cluster, 
                                                 create_args, [CLUSTER_PATH],
                                                 wait_time, retries)
        if origin_resources_checked
          body = JSON.generate(create_args)
          return _create(@batch_centroid_url, body)
        end
     end
 
     def get_batch_centroid(batch_centroid, query_string='')
       # Retrieves a batch centroid.
       BigML::check_resource_type(batch_centroid, BATCH_CENTROID_PATH, "A batch centroid id is needed.")
       batch_centroid_id = BigML::get_batch_centroid_id(batch_centroid)

       unless batch_centroid_id.nil?
         return _get(@url+batch_centroid_id, query_string)
       end
     end

     def download_batch_centroid(batch_centroid, filename=nil)
        # Retrieves the batch centroid file.
        # Downloads centroids, that are stored in a remote CSV file. If
        #   a path is given in filename, the contents of the file are downloaded
        #   and saved locally. A file-like object is returned otherwise.


        BigML::check_resource_type(batch_centroid, BATCH_CENTROID_PATH, "A batch centroid id is needed.")

        batch_centroid_id = BigML::get_batch_centroid_id(batch_centroid)
        unless batch_centroid_id.nil?
            return _download(@url+batch_centroid_id+DOWNLOAD_DIR, filename)
        end
     end 
 
     def list_batch_centroids(query_string='')
        # Lists all your batch centroids.
        return _list(@batch_centroid_url, query_string) 
     end

     def update_batch_centroid(batch_centroid, changes)
        # Updates a batch centroid. 
        BigML::check_resource_type(batch_centroid, BATCH_CENTROID_PATH, "A batch centroid is needed.")
        batch_centroid_id = BigML::get_batch_centroid_id(batch_centroid)
        unless batch_centroid_id.nil?
          return _update(@url+batch_centroid_id, JSON.generate(changes))
        end
     end

     def delete_batch_centroid(batch_centroid)
        # Deletes a batch centroid. 
        BigML::check_resource_type(batch_centroid, BATCH_CENTROID_PATH, "A batch centroid id is needed.")
        batch_centroid_id = BigML::get_batch_centroid_id(batch_centroid)
        unless batch_centroid_id.nil?
          return _delete(@url+batch_centroid_id)
        end
     end 
   
     ##########################################################################
     #
     # Batch Prediction 
     # https://bigml.com/developers/batchprediction
     ########################################################################## 
     def create_batch_prediction(model, dataset,
                                 args=nil, wait_time=3, retries=10)
        # Creates a new batch prediction.
        # The model parameter can be:
        # - a simple model
        # - an ensemble 

        create_args = args.nil? ? {} : args.clone

        origin_resources_checked = check_origins(dataset, model, create_args, 
                                                 SUPERVISED_PATHS,
                                                 wait_time, retries)
        if origin_resources_checked
           body = JSON.generate(create_args)
           return _create(@batch_prediction_url, body)
        end 

     end

     def get_batch_prediction(batch_prediction, query_string="")
        # Retrieves a batch prediction.
        BigML::check_resource_type(batch_prediction, BATCH_PREDICTION_PATH, "A batch prediction id is needed.")
        batch_prediction_id = BigML::get_batch_prediction_id(batch_prediction)

        unless batch_prediction_id.nil?
          return _get(@url+batch_prediction_id, query_string)
        end
     end
  
     def download_batch_prediction(batch_prediction, filename=nil)
        # Retrieves the batch predictions file.
        # Downloads predictions, that are stored in a remote CSV file. If
        # a path is given in filename, the contents of the file are downloaded
        # and saved locally. A file-like object is returned otherwise

        BigML::check_resource_type(batch_prediction, BATCH_PREDICTION_PATH, "A batch prediction id is needed.")

        batch_prediction_id = BigML::get_batch_prediction_id(batch_prediction)
        unless batch_prediction_id.nil?
            return _download(@url+batch_prediction_id+DOWNLOAD_DIR, filename)
        end
     end

     def list_batch_predictions(query_string='')
        # Lists all your batch predictions.
        return _list(@batch_prediction_url, query_string)
     end
 
     def update_batch_prediction(batch_prediction, changes)
        # Updates a batch prediction.
        BigML::check_resource_type(batch_prediction, BATCH_PREDICTION_PATH, "A batch prediction is needed.")
        batch_prediction_id = BigML::get_batch_prediction_id(batch_prediction)
        unless batch_prediction_id.nil?
          return _update(@url+batch_prediction_id, JSON.generate(changes))
        end
     end
  
     def delete_batch_prediction(batch_prediction)
        # Deletes a batch prediction.
        BigML::check_resource_type(batch_prediction, BATCH_PREDICTION_PATH, "A batch prediction id is needed.")
        batch_prediction_id = BigML::get_batch_prediction_id(batch_prediction)
        unless batch_prediction_id.nil?
          return _delete(@url+batch_prediction_id)
        end
     end

     ##########################################################################
     #
     # Correlation 
     # https://bigml.com/developers/correlation
     ##########################################################################

     def create_correlation(dataset, args=nil, wait_time=3, retries=10)
        # Creates a correlation from a `dataset`.
        dataset_id = nil 
        resource_type = BigML::get_resource_type(dataset)
        if resource_type == DATASET_PATH
            dataset_id = BigML::get_dataset_id(dataset)
            BigML::check_resource(dataset_id, nil,
                                   BigML::TINY_RESOURCE,
                                   wait_time, retries,
                                   true, self)
        else
            raise Exception, "A dataset id is needed to create a correlation. "+ resource_type + " found"
        end

        create_args = args.nil? ? {} : args.clone
        create_args["dataset"] = dataset_id

        body = JSON.generate(create_args)
        return _create(@correlation_url, body)
     end

     def get_correlation(correlation, query_string='')
        # Retrieves a correlation.
        BigML::check_resource_type(correlation, CORRELATION_PATH, "A correlation id is needed.")
        correlation_id = BigML::get_correlation_id(correlation)

        unless correlation_id.nil?
          return _get(@url+correlation_id, query_string)
        end
     end

     def list_correlations(query_string='')
        # Lists all your correlations.
        return _list(@correlation_url, query_string) 
     end
 
     def update_correlation(correlation, changes)
        # Updates a correlation. 
        BigML::check_resource_type(correlation, CORRELATION_PATH, "A correlation is needed.")
        correlation_id = BigML::get_correlation_id(correlation)
        unless correlation_id.nil?
          return _update(@url+correlation_id, JSON.generate(changes))
        end
     end

     def delete_correlation(correlation)
        # Deletes a correlation.
        BigML::check_resource_type(correlation, CORRELATION_PATH, "A correlation id is needed.")
        correlation_id = BigML::get_correlation_id(correlation)
        unless correlation_id.nil?
          return _delete(@url+correlation_id)
        end 
     end

     ##########################################################################
     #
     # Evaluation 
     # https://bigml.com/developers/evaluations
     ##########################################################################

     def create_evaluation(model, dataset, args=nil, wait_time=3, retries=10)
        # Creates a new evaluation.
        create_args = args.nil? ? {} : args.clone
 
        model_types = SUPERVISED_PATHS+[TIME_SERIES_PATH]
        origin_resources_checked = check_origins(dataset, model, create_args, 
                                                 model_types, wait_time, retries)

        if origin_resources_checked
           body = JSON.generate(create_args)
           return _create(@evaluation_url, body)
        end
 
     end
  
     def get_evaluation(evaluation, query_string='')
        # Retrieves a evaluation.
        BigML::check_resource_type(evaluation, EVALUATION_PATH, "A evaluation id is needed.")
        evaluation_id = BigML::get_evaluation_id(evaluation)

        unless evaluation_id.nil?
          return _get(@url+evaluation_id, query_string)
        end
     end

     def list_evaluations(query_string='')
        # Lists all your evaluations.
        return _list(@evaluation_url, query_string)
     end

     def update_evaluation(evaluation, changes)
        # Updates a evaluation. 
        BigML::check_resource_type(evaluation, EVALUATION_PATH, "A evaluation is needed.")
        evaluation_id = BigML::get_evaluation_id(evaluation)
        unless evaluation_id.nil?
          return _update(@url+evaluation_id, JSON.generate(changes))
        end
     end

     def delete_evaluation(evaluation)
        # Deletes a evaluation.
        BigML::check_resource_type(evaluation, EVALUATION_PATH, "A evaluation id is needed.")
        evaluation_id = BigML::get_evaluation_id(evaluation)
        unless evaluation_id.nil?
          return _delete(@url+evaluation_id)
        end
     end

     ##########################################################################
     #
     # Logistic Regression
     # https://bigml.com/developers/logisticregressions
     ##########################################################################

     def create_logisticregression(datasets, args=nil, wait_time=3, retries=10)
        # Creates a logistic regression from a `dataset`
        # of a list o `datasets`
        create_args = _set_create_from_datasets_args(datasets,args, wait_time, retries, nil)
        body = JSON.generate(create_args)
        return _create(@logistic_regression_url, body)
     end

     def logisticregression_is_ready(logistic_regression, args={})
       #Check whether a logistic regression status is FINISHED.
       BigML::check_resource_type(logistic_regression, LOGISTIC_REGRESSION_PATH, "A logistic regression id is needed.")
       logistic_regression = BigML::get_logisticregression(logistic_regression, args.fetch("query_string", nil))
       return BigML::resource_is_ready(logistic_regression)
     end

     def get_logisticregression(logistic_regression, query_string='',  shared_username=nil, shared_api_key=nil)
        # Retrieves a logistic regression.
        BigML::check_resource_type(logistic_regression, LOGISTIC_REGRESSION_PATH, "A logistic regression id is needed.")
        logistic_regression_id = BigML::get_logisticregression_id(logistic_regression)

        unless logistic_regression_id.nil?
          return _get(@url+logistic_regression_id, query_string, shared_username, shared_api_key)
        end
     end

     def list_logisticregressions(query_string='')
        # Lists all your logistic regression.
        return _list(@logistic_regression_url, query_string)
     end

     def update_logisticregression(logistic_regression, changes)
        # Updates a logistic regression. 
        BigML::check_resource_type(logistic_regression, LOGISTIC_REGRESSION_PATH, "A logistic regression is needed.")
        logistic_regression_id = BigML::get_logisticregression_id(logistic_regression)
        unless logistic_regression_id.nil?
          return _update(@url+logistic_regression_id, JSON.generate(changes))
        end
     end

     def delete_logisticregression(logistic_regression)
        # Deletes a logistic_regression.
        BigML::check_resource_type(logistic_regression, LOGISTIC_REGRESSION_PATH, "A logistic regression id is needed.")
        logistic_regression_id = BigML::get_logisticregression_id(logistic_regression)
        unless logistic_regression_id.nil?
          return _delete(@url+logistic_regression_id)
        end
     end

     ##########################################################################
     #
     # Samples 
     # https://bigml.com/developers/samples
     ##########################################################################

     def create_sample(dataset, args=nil, wait_time=3, retries=10)
        #Creates a sample from a `dataset`.
        dataset_id = nil
        resource_type = BigML::get_resource_type(dataset)
        if resource_type == DATASET_PATH
            dataset_id = BigML::get_dataset_id(dataset)
            BigML::check_resource(dataset_id, nil, BigML::TINY_RESOURCE,
                                   wait_time, retries,
                                   true, self)
        else
            raise Exception, "A dataset id is needed to create a sample. "+resource_type+ " found."
        end
       
        create_args = args.nil? ? {}: args.clone
        create_args["dataset"] = dataset_id

        body = JSON.generate(create_args)
        return _create(@sample_url, body)

     end

     def get_sample(sample, query_string='')
        # Retrieves a sample.
        BigML::check_resource_type(sample, SAMPLE_PATH, "A sample id is needed.")
        sample_id = BigML::get_sample_id(sample)

        unless sample_id.nil?
          return _get(@url+sample_id, query_string)
        end
     end

     def list_samples(query_string='')
        # Lists all your samples.
        return _list(@sample_url, query_string)
     end

     def update_sample(sample, changes)
        # Updates a sample. 
        BigML::check_resource_type(sample, SAMPLE_PATH, "A sample is needed.")
        sample_id = BigML::get_sample_id(sample)
        unless sample_id.nil?
          return _update(@url+sample_id, JSON.generate(changes))
        end
     end

     def delete_sample(sample)
        # Deletes a sample.
        BigML::check_resource_type(sample, SAMPLE_PATH, "A sample id is needed.")
        sample_id = BigML::get_sample_id(sample)
        unless sample_id.nil?
          return _delete(@url+sample_id)
        end
     end

     ##########################################################################
     #
     # statisticaltests
     # https://bigml.com/developers/statisticaltests
     ##########################################################################     

     def create_statistical_test(dataset, args=nil, wait_time=3, retries=10)
        # Creates a statistical test from a `dataset`.

        dataset_id = nil 
        resource_type = BigML::get_resource_type(dataset)
        if resource_type == DATASET_PATH
           dataset_id = BigML::get_dataset_id(dataset)
           BigML::check_resource(dataset_id, nil, TINY_RESOURCE,
                                 wait_time, retries,
                                 true, self)
        else
            raise Exception, "A dataset id is needed to create a statistical test. %s found." % resource_type
        end
 
        create_args = args.nil? ? {} : args.clone
        create_args["dataset"] = dataset_id

        body = JSON.generate(create_args)
        return _create(@statistical_test_url, body)
     end
   
     def get_statistical_test(statistical_test, query_string='')
        # Retrieves a statistical test.
        BigML::check_resource_type(statistical_test, STATISTICAL_TEST_PATH, "A statistical test id is needed.")
        statistical_test_id = BigML::get_statistical_test_id(statistical_test)

        unless statistical_test_id.nil?
          return _get(@url+statistical_test_id, query_string)
        end
     end

     def list_statistical_tests(query_string='')
        # Lists all your statistical_tests.
        return _list(@statistical_test_url, query_string)
     end

     def update_statistical_test(statistical_test, changes)
        # Updates a statistical_test. 
        BigML::check_resource_type(statistical_test, STATISTICAL_TEST_PATH, "A statistical test is needed.")
        statistical_test_id = BigML::get_statistical_test_id(statistical_test)
        unless statistical_test_id.nil?
          return _update(@url+statistical_test_id, JSON.generate(changes))
        end
     end

     def delete_statistical_test(statistical_test)
        # Deletes a statistical_test.
        BigML::check_resource_type(statistical_test, STATISTICAL_TEST_PATH, "A statistical test id is needed.")
        statistical_test_id = BigML::get_statistical_test_id(statistical_test)
        unless statistical_test.nil?
          return _delete(@url+statistical_test_id)
        end
     end 

     ##########################################################################
     #
     # scripts
     # https://bigml.com/developers/scripts
     ########################################################################## 

     def create_script(source_code=nil, args=nil,
                       wait_time=3, retries=10)
        # Creates a whizzml script from its source code. The `source_code`
        #   parameter can be a:
        #    {script ID}: the ID for an existing whizzml script
        #    {path}: the path to a file containing the source code
        #    {string} : the string containing the source code for the script

        create_args = args.nil? ? {} : args.clone

        if source_code.nil?
            raise Exception, 'A valid code string or a script id must be provided'
        end

        resource_type = BigML::get_resource_type(source_code)

        if resource_type == SCRIPT_PATH
            script_id = BigML::get_script_id(source_code)
            unless script_id.nil?
                check_resource(script_id, nil, BigML::TINY_RESOURCE,
                               wait_time, retries,
                               true, self)
                create_args["origin"] = script_id
            end
        elsif source_code.is_a?(String)
            begin
                if File.exist?(source_code)
                   File.open(source_code, "r") do |f|
                      source_code = f.read
                   end
                end
            rescue IOError
                raise IOError, "Could not open the source code file "+source_code 
            end

            create_args["source_code"] = source_code
        else
            raise Exception, "A script id or a valid source code is needed to create a script. "+ resource_type+ " found."

        end

        body = JSON.generate(create_args)
        return _create(@script_url, body)

     end

     def get_script(script, query_string='')
        # Retrieves a script.
        BigML::check_resource_type(script, SCRIPT_PATH, "A script id is needed.")
        script_id = BigML::get_script_id(script)

        unless script_id.nil?
          return _get(@url+script_id, query_string)
        end
     end

     def list_scripts(query_string='')
        # Lists all your scripts.
        return _list(@script_url, query_string)
     end

     def update_script(script, changes)
        # Updates a script. 
        BigML::check_resource_type(script, SCRIPT_PATH, "A script is needed.")
        script_id = BigML::get_script_id(script)
        unless script_id.nil?
          return _update(@url+script_id, JSON.generate(changes))
        end
     end

     def delete_script(script)
        # Deletes a script.
        BigML::check_resource_type(script, SCRIPT_PATH, "A script id is needed.")
        script_id = BigML::get_script_id(script)
        unless script_id.nil?
          return _delete(@url+script_id)
        end
     end

     ##########################################################################
     #
     # libraries
     # https://bigml.com/developers/libraries
     ########################################################################## 

     def create_library(source_code=nil, args=nil,
                        wait_time=3, retries=10)
        # Creates a whizzml library from its source code. The `source_code`
        #   parameter can be a:
        #    {library ID}: the ID for an existing whizzml library
        #    {path}: the path to a file containing the source code
        #    {string} : the string containing the source code for the library

        create_args = args.nil? ? {} : args.clone

        if source_code.nil?
            raise Exception, 'A valid code string or a library id must be provided'
        end

        resource_type = BigML::get_resource_type(source_code)
        if resource_type == LIBRARY_PATH
            library_id = BigML::get_library_id(source_code)
            unless library_id.nil?
                check_resource(library_id,nil, BigML::TINY_RESOURCE,
                               wait_time, retries,
                               true, self)
                create_args["origin"]=library_id
            end

        elsif source_code.is_a?(String) 
            begin 
              if File.exist?(source_code)
                 File.open(source_code, "r") do |f|
                   source_code = f.read
                 end
              end
            rescue IOError
                raise IOError , "Could not open the source code file %s. "+ source_code
            end

            create_args["source_code"] = source_code

        else
            raise Exception, "A library id or a valid source code is needed to create a library. "+ resource_type+ " found."
        end

        body = JSON.generate(create_args)
        return _create(@library_url, body)

     end

     def get_library(library, query_string='')
        # Retrieves a library.
        BigML::check_resource_type(library, LIBRARY_PATH, "A library id is needed.")
        library_id = BigML::get_library_id(library)

        unless library_id.nil?
          return _get(@url+library_id, query_string)
        end
     end

     def list_libraries(query_string='')
        # Lists all your libraries.
        return _list(@library_url, query_string)
     end

     def update_library(library, changes)
        # Updates a library. 
        BigML::check_resource_type(library, LIBRARY_PATH, "A library is needed.")
        library_id = BigML::get_library_id(library)
        unless library_id.nil?
          return _update(@url+library_id, JSON.generate(changes))
        end
     end

     def delete_library(library)
        # Deletes a library.
        BigML::check_resource_type(library, LIBRARY_PATH, "A library id is needed.")
        library_id = BigML::get_library_id(library)
        unless library_id.nil?
          return _delete(@url+library_id)
        end
     end

     ##########################################################################
     #
     # executions
     # https://bigml.com/developers/executions
     ########################################################################## 
    
     def create_execution(origin_resource, args=nil,
                         wait_time=3, retries=10)
        # Creates an execution from a `script` or a list of `scripts`.

        create_args = args.nil? ? {} : args.clone

        if origin_resource.is_a?(String) or origin_resource.is_a?(Hash)
            # single script
            scripts = [origin_resource]
        else
            scripts = origin_resource
        end
        script_ids = []
        begin
            scripts.each do |script|
               script_ids << BigML::get_script_id(script)
            end
        rescue Exception
          raise Exception, "A script id or a list of them is needed to create a script execution. "+BigML::get_resource_type(origin_resource) + " found. " 
        end

        if script_ids.all? {|script_id| BigML::get_resource_type(script_id) == SCRIPT_PATH } 
           scripts.each do |script|
              BigML::check_resource(script, nil, BigML::TINY_RESOURCE,
                                    wait_time, retries, true, self)
           end
        else
          raise Exception, "A script id or a list of them is needed to create a script execution. "+BigML::get_resource_type(origin_resource) + " found. " 
        end

        if scripts.size > 1
           create_args["scripts"] = script_ids
        else
           create_args["script"] = script_ids[0]
        end

        body = JSON.generate(create_args)
        return _create(@execution_url, body)

     end

     def get_execution(execution, query_string='')
        # Retrieves a execution.
        BigML::check_resource_type(execution, EXECUTION_PATH, "A execution id is needed.")
        execution_id = BigML::get_execution_id(execution)

        unless execution_id.nil?
          return _get(@url+execution_id, query_string)
        end
     end

     def list_executions(query_string='')
        # Lists all your executions.
        return _list(@execution_url, query_string)
     end

     def update_execution(execution, changes)
        # Updates a execution. 
        BigML::check_resource_type(execution, EXECUTION_PATH, "A execution is needed.")
        execution_id = BigML::get_execution_id(execution)
        unless execution_id.nil?
          return _update(@url+execution_id, JSON.generate(changes))
        end
     end

     def delete_execution(execution)
        # Deletes a execution.
        BigML::check_resource_type(execution, EXECUTION_PATH, "A execution id is needed.")
        execution_id = BigML::get_execution_id(execution)
        unless execution_id.nil?
          return _delete(@url+execution_id)
        end
     end

     ##########################################################################
     #
     # Projects
     #
     ##########################################################################
     def create_project(args)
       # Creates a project.
       body=JSON.generate(args.nil? ? {} : args)
       return _create(@project_url, body, nil, true) 
       
     end

     def get_project(project, query_string='')
        # Retrieves a project.
        # The project parameter should be a string containing the
        # project id or the dict returned by create_project.
        # As every resource, is an evolving object that is processed
        # until it reaches the FINISHED or FAULTY state. The function will
        # return a dict that encloses the project values and state info
        # available at the time it is called.

        BigML::check_resource_type(project, PROJECT_PATH, "A project id is needed.")
        project_id = BigML::get_project_id(project)
        unless project_id.nil?
          return _get(@url+project_id, query_string, nil, nil, true)
        end
     end 
     
     def list_projects(query_string='')
       # Lists all your remote projects.
       return _list(@project_url, query_string, true)
     end

     def update_project(project, changes)
       # Updates a project.
       # Updates remote `project` with `changes'.
       BigML::check_resource_type(project, PROJECT_PATH, "A project id is needed.")
       project_id = BigML::get_project_id(project)
       unless project_id.nil?
          return _update(@url+project_id, JSON.generate(changes), true)
       end
     end

     def delete_project(project)
       #Deletes a remote project permanently.
       BigML::check_resource_type(project, PROJECT_PATH, "A project id is needed.")
       project_id = BigML::get_project_id(project)
       unless project_id.nil?
          return _delete(@url+project_id, '', true)
       end
     end

     def delete_all_project_by_name(name)
        projects = list_projects("name="+name)
        unless projects.nil?
           projects["objects"].each do |project|
              delete_project(project["resource"])
           end 
        end
     end

     ##########################################################################
     #
     #  TopicModel's REST calls 
     #  https://bigml.com/developers/topicmodels
     ##########################################################################
     def create_topic_model(datasets, args=nil, wait_time=3, retries=10)
       # Creates an Topic Model from a `dataset` or a list o `datasets`

       create_args=_set_create_from_datasets_args(datasets,
                                                  args,
                                                  wait_time,
                                                  retries)
       return _create(@topic_model_url, JSON.generate(create_args))

     end

     def get_topic_model(topic_model, query_string='', shared_username=nil, shared_api_key=nil)
        # Retrieves an TOPIC MODEL.

        # The topic_model parameter should be a string containing the
        # topic model id or the dict returned by create_topic_model.
        # As topic model is an evolving object that is processed
        # until it reaches the FINISHED or FAULTY state, the function will
        # return a dict that encloses the topic model values and state info
        # available at the time it is called.

        # If this is a shared topic model, the username and sharing api key must
        # also be provided.
 
        BigML::check_resource_type(topic_model, TOPIC_MODEL_PATH, "An Topic Model id is needed.")
        topic_model_id = BigML::get_topic_model_id(topic_model)
        unless topic_model_id.nil?
          return _get(@url+topic_model_id, query_string, shared_username, shared_api_key)
        end
     end
     
     def get_topicmodel(topic_model, query_string='', shared_username=nil, shared_api_key=nil)
       self.get_topic_model(topic_model, query_string, shared_username, shared_api_key)
     end  

     def topic_model_is_ready(topic_model, args={})
       #Check whether an Topic Model's  status is FINISHED.
       BigML::check_resource_type(topic_model, TOPIC_MODEL_PATH, "An Topic Model id is needed.")
       topic_model = get_topic_model(topic_model, args.fetch("query_string", nil),
                         args.fetch("shared_username", nil),
                         args.fetch("shared_api_key", nil))
       return resource_is_ready(topic_model)
     end

     def list_topic_models(query_string='')
       # Lists all your topic_model 
       return _list(@topic_model_url, query_string)
     end

     def update_topic_model(topic_model, changes)
       # Updates a Topic Model.
       BigML::check_resource_type(topic_model, TOPIC_MODEL_PATH, "An Topic Model id is needed.")
       topic_model_id = BigML::get_topic_model_id(topic_model)
       unless topic_model_id.nil?
          return _update(@url+topic_model_id, JSON.generate(changes))
       end
     end

     def delete_topic_model(topic_model)
       #Deletes a Topic Model.
       BigML::check_resource_type(topic_model, TOPIC_MODEL_PATH, "An Topic Model id is needed.")
       topic_model_id = BigML::get_topic_model_id(topic_model)
       unless topic_model_id.nil?
          return _delete(@url+topic_model_id)
       end
     end

     ##########################################################################
     #
     #  topicdistributions' REST calls
     #  https://bigml.com/developers/topic_distributions
     ##########################################################################


     def create_topic_distribution(topic_model, input_data=nil, args=nil, wait_time=3, retries=10)
       # Creates a new topic distribution 

       topic_model_id = BigML::get_topic_model_id(topic_model)
       unless topic_model_id.nil?
         BigML::check_resource(topic_model_id, nil, BigML::TINY_RESOURCE, 
                               wait_time, retries, true, self)
       else
         resource_type = BigML::get_resource_type(model)
         raise Exception, "A topic model id is needed to create a topic distribution. %s found" % resource_type
       end

       input_data = input_data.nil? ? {} : input_data
       create_args = {}
       unless args.nil?
         create_args=args.clone
       end

       create_args["input_data"] = input_data
       create_args["topicmodel"] = topic_model_id

       body = JSON.generate(create_args)

       return _create(@topic_distribution_url, body) 

     end

     def get_topic_distribution(topic_distribution, query_string='')
        # Retrieves a topic distribution.

        BigML::check_resource_type(topic_model, TOPIC_DISTRIBUTION_PATH, "An Topic Distribution id is needed.")
        topic_distribution_id = BigML::get_topic_distribution_id(topic_distribution)
        unless topic_distribution_id.nil?
          return _get(@url+topic_distribution_id, query_string)
        end
     end

     def list_topic_distributions(query_string='')
       # Lists all your topic distributions
       return _list(@topic_distribution_url, query_string)
     end

     def update_topic_distribution(topic_distribution, changes)
       # Updates a Topic Model.
       BigML::check_resource_type(topic_distribution, TOPIC_DISTRIBUTION_PATH, "An Topic distribution id is needed.")
       topic_model_id = BigML::get_topic_distribution_id(topic_model)
       unless topic_model_id.nil?
          return _update(@url+topic_model_id, JSON.generate(changes))
       end
     end

     def delete_topic_distribution(topic_distribution)
       #Deletes a Topic Distribution.
       BigML::check_resource_type(topic_distribution, TOPIC_DISTRIBUTION_PATH, "An Topic Distribution id is needed.")
       topic_distribution_id = BigML::get_topic_distribution_id(topic_distribution)
       unless topic_distribution_id.nil?
          return _delete(@url+topic_distribution_id)
       end
     end

     ##########################################################################
     #
     #  topicdistributions' REST calls
     #  https://bigml.com/developers/topic_distributions
     ##########################################################################

     def create_batch_topic_distribution(topic_model, dataset, args=nil, wait_time=3, retries=10)
       # Creates a new batch topic distribution.
       create_args = args.nil? ? {} : args.clone

       origin_resources_checked = check_origins(dataset, topic_model, create_args,
                                                [TOPIC_MODEL_PATH], wait_time, retries)
       if origin_resources_checked
          body = JSON.generate(create_args)
          return _create(@batch_topic_distribution_url, body)
       end
     end    

     def get_batch_topic_distribution(batch_topic_distribution, query_string='')
        # Retrieves a batch topic distribution.

        # the batch_topic_distribution parameter should be a string
        # containing the batch_topic_distribution id or the dict
        # returned by create_batch_topic_distribution.
        # As batch_topic_distribution is an evolving object that is processed
        # until it reaches the FINISHED or FAULTY state, the function will
        # return a dict that encloses the batch_topic_distribution values
        # and state info available at the time it is called.

        BigML::check_resource_type(batch_topic_model, BATCH_TOPIC_DISTRIBUTION_PATH, "An Batch Topic Distribution id is needed.")
        batch_topic_distribution_id = BigML::get_batch_topic_distribution_id(batch_topic_distribution)
        unless batch_topic_distribution_id.nil?
          return _get(@url+batch_topic_distribution_id, query_string)
        end
     end 

     def download_batch_topic_distribution(batch_topic_distribution, filename=nil)
        # Retrieves the batch topic distribution file
        # Downloads topic distributions, that are stored in a remote CSV file.
        # If a path is given in filename, the contents of the file are
        # downloaded and saved locally. A file-like object is returned
        # otherwise.

        BigML::check_resource_type(batch_topic_distribution, BATCH_TOPIC_DISTRIBUTION_PATH, "A batch topic distribution id is needed.")

        batch_topic_distribution_id = BigML::get_batch_topic_distribution_id(batch_topic_distribution)
        unless batch_topic_distribution_id.nil?
            return _download(@url+batch_topic_distribution_id+DOWNLOAD_DIR, filename)
        end
     end

     def list_batch_topic_distributions(query_string='')
       # Lists all your batch topic distributions
       return _list(@topic_batch_distribution_url, query_string)
     end

     def update_batch_topic_distribution(batch_topic_distribution, changes)
       # Updates a Topic Model.
       BigML::check_resource_type(batch_topic_distribution, BATCH_TOPIC_DISTRIBUTION_PATH, "An Batch topic distribution id is needed.")
       batch_topic_distribution_id = BigML::get_batch_topic_distribution_id(batch_topic_model)
       unless batch_topic_distribution_id.nil?
          return _update(@url+batch_topic_model_id, JSON.generate(changes))
       end
     end

     def delete_batch_topic_distribution(batch_topic_distribution)
       #Deletes a Batch Topic Distribution.
       BigML::check_resource_type(batch_topic_distribution, BATCH_TOPIC_DISTRIBUTION_PATH, "An Batch topic Distribution id is needed.")
       batch_topic_distribution_id = BigML::get_batch_topic_distribution_id(batch_topic_distribution)
       unless batch_topic_distribution_id.nil?
          return _delete(@url+batch_topic_distribution_id)
       end
     end

     ##########################################################################
     #
     # timeseries 
     # https://bigml.com/developers/timeseries
     ##########################################################################
     def create_time_series(datasets, args=nil, wait_time=3, retries=10)
        #Creates a time series from a `dataset` or a list o `datasets`.

        create_args = _set_create_from_datasets_args(datasets,args,
                                                     wait_time, retries, nil)

        body = JSON.generate(create_args)
        return _create(@time_series_url, body)
     end

     def get_timeseries(time_series, query_string='',
                     shared_username=nil, shared_api_key=nil)
         return get_time_series(time_series, query_string='',
                                shared_username=nil, shared_api_key=nil)
     end
     
     def get_time_series(time_series, query_string='',
                     shared_username=nil, shared_api_key=nil)
        #Retrieves a time series

        BigML::check_resource_type(time_series, TIME_SERIES_PATH, "A time series id is needed.")
        time_series_id = BigML::get_time_series_id(time_series)

        unless time_series_id.nil?
          return _get(@url+time_series_id, query_string,
                     shared_username, shared_api_key)
        end
     end

     def time_series_is_ready(time_series, args={})
       #Check whether a time series status is FINISHED.
       BigML::check_resource_type(time_series, TIME_SERIES_PATH, "A time series id is needed.")
       time_series = get_time_series(time_series, args.fetch("query_string", nil),
                         args.fetch("shared_username", nil),
                         args.fetch("shared_api_key", nil))
       return resource_is_ready(time_series)
     end

     def list_time_series(query_string='')
       # Lists all your time series
       return _list(@time_series_url, query_string)
     end 

     def update_time_series(time_series, changes)
       # Updates a time series.
       # Updates remote `time series` with `changes'.
       BigML::check_resource_type(time_series, TIME_SERIES_PATH, "A time series id is needed.")
       time_series_id = BigML::get_time_series_id(time_series)
       unless time_series_id.nil?
          return _update(@url+time_series_id, JSON.generate(changes))
       end
     end

     def delete_time_series(time_series)
       #Deletes a remote time series permanently.
       BigML::check_resource_type(time_series, TIME_SERIES_PATH, "A time series id is needed.")
       time_series_id = BigML::get_time_series_id(time_series)
       unless time_series_id.nil?
          return _delete(@url+time_series_id)
       end
     end

     ##########################################################################
     #
     # forecasts
     # https://bigml.com/developers/forecasts
     ##########################################################################

     def create_forecast(time_series, input_data=nil,
                         args=nil, wait_time=3, retries=10)
        #Creates a new forecast.
        time_series_id = BigML::get_time_series_id(time_series)
        resource_type = BigML::get_resource_type(time_series_id)
        if resource_type == TIME_SERIES_PATH and 
            !time_series_id.nil?
            BigML::check_resource(time_series_id, nil,
                                  BigML::TINY_RESOURCE,
                                  wait_time,retries,
                                  true, self)
        else
            raise Exception, "A time series id is needed to create a forecast. "+resource_type + ". found"
        end

        input_data = input_data.nil? ? {} : input_data.clone
        create_args = args.nil? ? {} : args
        create_args["input_data"] = input_data
        if !time_series_id.nil?
          create_args["timeseries"] = time_series_id
        end
        
        body = JSON.generate(create_args)
        return _create(@forecast_url, body, @verify_prediction)
     end



     def get_forecast(forecast, query_string='')
        #Retrieves a forecast

        BigML::check_resource_type(forecast, FORECAST_PATH, "A forecast id is needed.")
        forecast_id = BigML::get_forecast_id(forecast)

        unless forecast_id.nil?
          return _get(@url+forecast_id, query_string)
        end
     end

     def list_forecast(query_string='')
       # Lists all your forecast 
       return _list(@forecast_url, query_string)
     end

     def update_forecast(forecast, changes)
       # Updates a forecast 
       # Updates remote `forecast` with `changes'.
       BigML::check_resource_type(forecast, FORECAST_PATH, "A forecast id is needed.")
       forecast_id = BigML::get_forecast_id(forecast)
       unless forecast_id.nil?
          return _update(@url+forecast_id, JSON.generate(changes))
       end
     end

     def delete_forecast(forecast)
       #Deletes a remote forecast permanently.
       BigML::check_resource_type(forecast, FORECAST_PATH, "A forecast id is needed.")
       forecast_id = BigML::get_forecast_id(forecast)
       unless forecast_id.nil?
          return _delete(@url+forecast_id)
       end
     end

     ##########################################################################
     #
     # deepnets 
     # https://bigml.com/developers/deepnets
     ##########################################################################
     def create_deepnets(datasets, args=nil, wait_time=3, retries=10)
        #Creates a deepnet from a `dataset` or a list o `datasets`.

        create_args = _set_create_from_datasets_args(datasets,args,
                                                     wait_time, retries, nil)

        body = JSON.generate(create_args)
        return _create(@deepnet_url, body)
     end
 
     def get_deepnet(deepnet, query_string='',
                     shared_username=nil, shared_api_key=nil)
        #Retrieves a deepnet
        #  The model parameter should be a string containing the
        #   deepnet id or the dict returned by
        #   create_deepnet.
        #   As a deepnet is an evolving object that is processed
        #   until it reaches the FINISHED or FAULTY state, the function will
        #   return a dict that encloses the deepnet
        #   values and state info available at the time it is called.
        #   If this is a shared deepnet, the username and
        #   sharing api key must also be provided.

        BigML::check_resource_type(deepnet, DEEPNET_PATH, "A deepnet id is needed.")
        deepnet_id = BigML::get_deepnet_id(deepnet)

        unless deepnet_id.nil?
          return _get(@url+deepnet_id, query_string,
                     shared_username, shared_api_key)
        end
     end

     def deepnet_is_ready(deepnet, args={})
       #Check whether a deepnet status is FINISHED.
       BigML::check_resource_type(deepnet, DEEPNET_PATH, "A deepnet id is needed.")
       deepnet = get_deepnet(deepnet, args.fetch("query_string", nil),
                         args.fetch("shared_username", nil),
                         args.fetch("shared_api_key", nil))
       return resource_is_ready(deepnet)
     end

     def list_deepnets(query_string='')
       # Lists all your deepnet 
       return _list(@deepnet_url, query_string)
     end

     def update_deepnet(deepnet, changes)
       # Updates a deepnet.
       # Updates remote `deepnet` with `changes'.
       BigML::check_resource_type(deepnet, DEEPNET_PATH, "A deepnet id is needed.")
       deepnet_id = BigML::get_deepnet_id(time_series)
       unless deepnet_id.nil?
          return _update(@url+deepnet_id, JSON.generate(changes))
       end
     end

     def delete_deepnet(deepnet)
       #Deletes a remote deepnet permanently.
       BigML::check_resource_type(deepnet, DEEPNET_PATH, "A deepnet id is needed.")
       deepnet_id = BigML::get_deepnet_id(deepnet)
       unless deepnet_id.nil?
          return _delete(@url+deepnet_id)
       end
     end
   
     ##########################################################################
     #
     # deepnets 
     # https://bigml.com/developers/configurations
     ##########################################################################
     
     def create_configuration(configurations, args=nil)
        #Creates a configuratoin from a `configurations` dictionary

        if !configurations.is_a?(Hash)
          raise ArgumentError, "Failed to find a configuration dictionary as first argument."
        end
          
        if args.nil?
          args = {}
        end
        create_args = {"configurations" => configurations}.merge(args)
          
        body = JSON.generate(create_args)
        return _create(@configuration_url, body)
     end
    
     def get_configuration(configuration, query_string='')
       
        #Retrieves a configuration
        #  The configuration parameter should be a string containing the
        #   configuration id or the dict returned by create_configuration.
      
        BigML::check_resource_type(configuration, CONFIGURATION_PATH, "A configuration id is needed.")
        configuration_id = BigML::get_configuration_id(configuration)

        unless configuration_id.nil?
          return _get(@url+configuration_id, query_string)
        end
     end

     def list_configurations(query_string='')
       # Lists all your configurations 
       return _list(@configuration_url, query_string)
     end
     
     def update_configuration(configuration, changes)
       # Updates a configuration
       BigML::check_resource_type(configuration, CONFIGURATION_PATH, "A configurations id is needed.")
       configuration_id = BigML::get_configuration_id(configuration)
       unless configuration_id.nil?
          return _update(@url+configuration_id, JSON.generate(changes))
       end
     end
     
     def delete_configuration(configuration)
       #Deletes a remote configuration permanently.
       BigML::check_resource_type(configuration, CONFIGURATION_PATH, "A configuration id is needed.")
       configuration_id = BigML::get_configuration_id(configuration)
       unless configuration_id.nil?
          return _delete(@url+configuration_id)
       end
     end
     
     def source_from_batch_prediction(batch_prediction, args=nil)
       # Creates a source from a batch prediction using the download url
        BigML::check_resource_type(batch_prediction, BATCH_PREDICTION_PATH, "A batch prediction id is needed.")
        batch_prediction_id = BigML::get_batch_prediction_id(batch_prediction)
     
        if batch_prediction_id
          download_url = "%s%s%s%s" % [@url, batch_prediction_id, DOWNLOAD_DIR, @auth]
          return _create_remote_source(download_url, args)
        end 
     end  
     
     ##########################################################################
     #
     # fusions 
     # https://bigml.com/developers/fusions
     ##########################################################################
     def create_fusion(models, args=nil, wait_time=3, retries=10)
        # Creates a fusion from a list of supervised models

        create_args = _set_create_from_models_args(models,BigML::SUPERVISED_PATHS, args, 
                                                   wait_time, retries)

        body = JSON.generate(create_args)
        return _create(@fusion_url, body)
     end
     
     def get_fusion(fusion, query_string='', shared_username=nil, shared_api_key=nil)
       
       #   Retrieves a fusion.
       #
       #   The model parameter should be a string containing the
       #   fusion id or the dict returned by
       #   create_fusion.
       #   As a fusion is an evolving object that is processed
       #   until it reaches the FINISHED or FAULTY state, the function will
       #   return a dict that encloses the fusion
       #   values and state info available at the time it is called.
       #
       #   If this is a shared fusion, the username and
       #   sharing api key must also be provided.
       #
      
        BigML::check_resource_type(fusion, FUSION_PATH, "A fusion id is needed.")
        fusion_id = BigML::get_fusion_id(fusion)

        unless fusion_id.nil?
          return _get(@url+fusion_id, query_string,
                     shared_username, shared_api_key)
        end
     end
     
     def fusion_is_ready(fusion, args={})
       #Check whether a fusion's status is FINISHED.
       BigML::check_resource_type(fusion, FUSION_PATH, "A fusion id is needed.")
       resource = get_fusion(fusion, args.fetch("query_string", nil),
                         args.fetch("shared_username", nil),
                         args.fetch("shared_api_key", nil))
       return resource_is_ready(resource)
     end
     
     def list_fusions(query_string='')
       # Lists all your fusions 
       return _list(@fusion_url, query_string)
     end
     
     def update_fusion(fusion, changes)
       # Updates a fusion
       BigML::check_resource_type(fusion, FUSION_PATH, "A fusion id is needed.")
       fusion_id = BigML::get_fusion_id(fusion)
       unless fusion_id.nil?
          return _update(@url+fusion_id, JSON.generate(changes))
       end
     end
     
     def delete_fusion(fusion)
       #Deletes a remote fusion permanently.
       BigML::check_resource_type(fusion, FUSION_PATH, "A fusion id is needed.")
       fusion_id = BigML::get_fusion_id(fusion)
       unless fusion_id.nil?
          return _delete(@url+fusion_id)
       end
     end
     
     ##########################################################################
     #
     # optiml's 
     # https://bigml.com/developers/optimls
     ##########################################################################
     def create_optiml(datasets, args=nil, wait_time=3, retries=10)
        # Creates a optiml from a dataset of a list of `datasets`

        create_args = _set_create_from_datasets_args(datasets,args,
                                                     wait_time, retries, nil)

        body = JSON.generate(create_args)
        return _create(@optiml_url, body)
     end
     
     def get_optiml(optiml, query_string='', shared_username=nil, shared_api_key=nil)
       
       #   Retrieves a fusion.
       #
       #   The model parameter should be a string containing the
       #   fusion id or the dict returned by
       #   create_optiml.
       #   As a fusion is an evolving object that is processed
       #   until it reaches the FINISHED or FAULTY state, the function will
       #   return a dict that encloses the fusion
       #   values and state info available at the time it is called.
       #
       #   If this is a shared fusion, the username and
       #   sharing api key must also be provided.
       #
      
        BigML::check_resource_type(optiml, OPTIML_PATH, "An optiml id is needed.")
        optiml_id = BigML::get_optiml_id(optiml)

        unless optiml_id.nil?
          return _get(@url+optiml_id, query_string,
                     shared_username, shared_api_key)
        end
     end
     
     def optiml_is_ready(fusion, args={})
       #Check whether a optiml's status is FINISHED.
       BigML::check_resource_type(optiml, FUSION_PATH, "An optiml id is needed.")
       resource = get_optiml(optiml, args.fetch("query_string", nil),
                         args.fetch("shared_username", nil),
                         args.fetch("shared_api_key", nil))
       return resource_is_ready(resource)
     end
     
     def list_optimls(query_string='')
       # Lists all your optimls 
       return _list(@optiml_url, query_string)
     end
     
     def update_optiml(optiml, changes)
       # Updates a configuration
       BigML::check_resource_type(optiml, OPTIML_PATH, "An optiml id is needed.")
       optiml_id = BigML::get_optiml_id(optiml)
       unless optiml_id.nil?
          return _update(@url+optiml_id, JSON.generate(changes))
       end
     end
     
     def delete_optiml(optiml)
       #Deletes a remote optiml permanently.
       BigML::check_resource_type(optiml, OPTIML_PATH, "An optiml id is needed.")
       optiml_id = BigML::get_optiml_id(fusion)
       unless optiml_id.nil?
          return _delete(@url+optiml_id)
       end
     end
   
  end
end  
